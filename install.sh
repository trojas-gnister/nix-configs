#!/usr/bin/env bash

# Check if fzf is installed, if not, install it using nix-env
if ! command -v fzf &> /dev/null; then
  echo "fzf is not installed. Installing fzf..."
  nix-env -iA nixos.fzf
  if [ $? -ne 0 ]; then
    echo "Failed to install fzf. Please ensure your Nix package manager is configured correctly."
    exit 1
  fi  
fi

echo "Available storage devices:"
DEVICE=$(lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd|^vd|^nvme' | fzf --prompt="Select a storage device: " | awk '{print $1}')

# Confirm the device input
if [ -z "$DEVICE" ]; then
  echo "No device selected. Exiting."
  exit 1
fi

# Check for existing partitions
if lsblk /dev/$DEVICE | grep -q 'part'; then
  read -p "/dev/$DEVICE already has partitions. Do you want to delete everything and proceed? (yes/no): " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "Script is unable to proceed due to existing partitions on the device."
    exit 1
  else
    echo "Deleting existing partitions on /dev/$DEVICE..."
    # Use wipefs to remove existing partitions
    wipefs --all /dev/$DEVICE
    sgdisk --zap-all /dev/$DEVICE
  fi
fi

# Ask if the user wants to encrypt their partitions
read -p "Do you want to encrypt your partitions? (yes/no): " ENCRYPT

if [[ "$ENCRYPT" == "yes" ]]; then
  # Prompt for encryption password
  read -s -p "Enter encryption password: " ENCRYPT_PWD
  echo
  read -s -p "Confirm encryption password: " ENCRYPT_PWD_CONFIRM
  echo
  if [[ "$ENCRYPT_PWD" != "$ENCRYPT_PWD_CONFIRM" ]]; then
    echo "Passwords do not match. Exiting."
    exit 1
  fi
fi

# Ask the user to set the amount of swap storage
read -p "Enter the desired swap size in GB (e.g., 4 for 4GB): " SWAP_SIZE

# Proceeding to partition
echo "Proceeding to partition /dev/$DEVICE..."

# Convert SWAP_SIZE to integer and ensure it's valid
if ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
  echo "Invalid swap size. Please enter a numeric value."
  exit 1
fi

# Create partitions using sgdisk
sgdisk -n 1:0:+512M -t 1:EF00 /dev/$DEVICE  # Boot partition (512 MB, EFI System)
sgdisk -n 2:0:+"${SWAP_SIZE}"G -t 2:8300 /dev/$DEVICE    # Swap partition
sgdisk -n 3:0:0 -t 3:8300 /dev/$DEVICE      # Root partition (remaining space)

# Format partitions
echo "Formatting partitions..."

mkfs.fat -F 32 /dev/${DEVICE}1  # Boot partition

if [[ "$ENCRYPT" == "yes" ]]; then
  # Set up LUKS encryption on swap and root partitions
  echo "Setting up encryption on root and swap partitions..."

  # Encrypt swap partition
  echo -n "$ENCRYPT_PWD" | cryptsetup luksFormat /dev/${DEVICE}2 -
  echo -n "$ENCRYPT_PWD" | cryptsetup open /dev/${DEVICE}2 swapcrypt -

  # Encrypt root partition
  echo -n "$ENCRYPT_PWD" | cryptsetup luksFormat /dev/${DEVICE}3 -
  echo -n "$ENCRYPT_PWD" | cryptsetup open /dev/${DEVICE}3 rootcrypt -

  # Format the encrypted partitions
  mkswap /dev/mapper/swapcrypt          # Swap partition
  mkfs.ext4 /dev/mapper/rootcrypt       # Root partition

  # Mount partitions
  echo "Mounting partitions..."

  mount /dev/mapper/rootcrypt /mnt
  mkdir -p /mnt/boot
  mount /dev/${DEVICE}1 /mnt/boot
  swapon /dev/mapper/swapcrypt

else
  # No encryption
  mkswap /dev/${DEVICE}2          # Swap partition
  mkfs.ext4 /dev/${DEVICE}3       # Root partition

  # Mount partitions
  echo "Mounting partitions..."

  mount /dev/${DEVICE}3 /mnt
  mkdir -p /mnt/boot
  mount /dev/${DEVICE}1 /mnt/boot
  swapon /dev/${DEVICE}2
fi

echo "Generating NixOS configuration..."
nixos-generate-config --root /mnt

# Replace generated configuration.nix with the preconfigured one from the GitHub repository
echo "Fetching preconfigured configuration.nix from the GitHub repository..."
curl -o /mnt/etc/nixos/configuration.nix https://raw.githubusercontent.com/trojas-gnister/NixVMHostForge/main/app-nix-configs/librewolf-i3/configuration.nix

if [ $? -ne 0 ]; then
  echo "Failed to download configuration.nix. Please check the URL and your internet connection."
  exit 1
fi

echo "Preconfigured configuration.nix has been downloaded and replaced."

echo "Starting NixOS installation..."
nixos-install

if [ $? -eq 0 ]; then
  echo "NixOS installation completed successfully!"
  
  # Create the .config/i3 directory in the user's home directory
  echo "Setting up i3 configuration..."
  mkdir -p /mnt/home/nixos/.config/i3
  
  # Download the i3 config file
  curl -o /mnt/home/nixos/.config/i3/config https://raw.githubusercontent.com/trojas-gnister/NixVMHostForge/main/app-nix-configs/librewolf-i3/i3/config
  
  if [ $? -ne 0 ]; then
    echo "Failed to download i3 config file. Please check the URL and your internet connection."
    exit 1
  fi
  
  # Set the appropriate ownership
  chown -R nixos:users /mnt/home/nixos/.config
  
  echo "i3 configuration has been set up."
  
  echo "You can now reboot your system."
else
  echo "NixOS installation encountered an error. Please check the output above for details."
  exit 1
fi
