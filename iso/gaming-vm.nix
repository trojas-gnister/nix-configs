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
    printf 'label: gpt\n,1G,U,*\n,,L\n' | sfdisk /dev/vda

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

    # 3. Prepare NixOS configuration directory
    echo "Creating /mnt/etc/nixos directory..."
    mkdir -p /mnt/etc/nixos

    # 4. Clone config to home directory and copy necessary files
    echo "Cloning nix-configs to home and copying to /mnt/etc/nixos..."
    cd /root
    git clone https://github.com/trojas-gnister/nix-configs
    cp -r nix-configs/flake.nix nix-configs/hosts nix-configs/iso nix-configs/lib nix-configs/modules /mnt/etc/nixos/

    # 5. Create the VM-specific variables.nix
    echo "Creating variables.nix for the new VM..."
    cat > /mnt/etc/nixos/variables.nix <<'EOF'
{ config, lib, pkgs, ... }:
{
  imports = [ ./lib/variables-module.nix ];

  variables = {
    packages = {
      system = [
      ];
      homeManager = [
        "kitty"
        "tmux"
        "btop"
        "librewolf"
        "pavucontrol"
        "networkmanagerapplet"
        "blueman"
        "neovim"
      ];
      unfree = [
        "steamdeck-hw-theme"
        "steam-jupiter-unwrapped"
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
        "xow_dongle-firmware"
      ];
    };

    user = {
      name = "user";
      groups = [  "wheel" "audio" "video" ];
    };

    firewall = {
      openTCPPorts = [
      ];
      openUDPPorts = [
      ];
      openUDPPortRanges = [
      ];
      trustedInterfaces = [ ];
    };
  };
}
EOF

    # 6. Generate the hardware-specific configuration
    echo "Generating hardware configuration..."
    nixos-generate-config --root /mnt

    # 7. Install NixOS using the 'blackspace' configuration from your flake
    echo "Installing NixOS from flake: /mnt/etc/nixos#blackspace"
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake /mnt/etc/nixos#blackspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
