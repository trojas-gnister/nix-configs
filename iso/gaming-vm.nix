{ pkgs, nixpkgs }:
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
  ];

  boot.kernelParams = [ "console=ttyS0,115200" ];
  system.stateVersion = "24.11";

  users.users.root.password = "root";

  environment.systemPackages = with pkgs; [
    git
    neovim
    python3
    rustc
    tmux
    gptfdisk
    parted
  ];

  environment.etc."profile.d/install.sh".text = ''
    # This script will run once upon login and perform a fully automated installation.

    if [ -f /tmp/install_started.lock ]; then
      echo "Installation script has already run. Not running again."
      exit 0
    fi
    touch /tmp/install_started.lock

    echo "--- STARTING AUTOMATED NIXOS INSTALLATION ---"
    set -e # Exit immediately if a command fails

    # 1. Partition and format the disk for a UEFI system
    echo "Partitioning and formatting /dev/vda..."
    sfdisk /dev/vda <<EOF
    label: gpt
    ,1G,U,*
    ,,L
    EOF
    partprobe /dev/vda
    sleep 2
    mkfs.fat -F 32 -n boot /dev/vda1
    mkfs.ext4 -F -L root /dev/vda2

    # 2. Mount the filesystems
    echo "Mounting filesystems..."
    mkdir -p /mnt
    mount /dev/disk/by-label/root /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot

    # 3. Generate the hardware-specific configuration first
    echo "Generating hardware configuration..."
    nixos-generate-config --root /mnt

    # 4. Clone your NixOS configuration into a temporary location
    echo "Cloning nix-configs repository..."
    git clone https://github.com/trojas-gnister/nix-configs /tmp/nix-configs

    # 5. Copy your repository files into the final location
    echo "Copying repository files into place..."
    cp -rT /tmp/nix-configs/ /mnt/etc/nixos/

    # 6. Clean up the temporary clone and unnecessary files
    echo "Cleaning up configuration directory..."
    rm -rf /tmp/nix-configs
    rm -f /mnt/etc/nixos/configuration.nix
    rm -f /mnt/etc/nixos/.gitignore
    rm -rf /mnt/etc/nixos/.git
    
    # 7. Create a minimal variables.nix for the new VM
    echo "Creating minimal variables.nix for the new VM..."
    cat > /mnt/etc/nixos/variables.nix <<'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ./lib/variables-module.nix ];

      variables = {
        networking.hostname = "nixos-vm";

        user = {
          name = "user";
          password = "password";
          groups = [ "wheel" "audio" "video" "networkmanager" "libvirtd" ];
        };
      };
    }
    EOF

    # 8. Install NixOS using the 'blackspace' configuration from your flake
    echo "Installing NixOS from flake: /mnt/etc/nixos#blackspace"
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake /mnt/etc/nixos#blackspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
