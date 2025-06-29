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
  ];

  environment.etc."profile.d/install.sh".text = ''
    # This script will run once upon login and perform a fully automated installation.

    if [ -f /tmp/install_started.lock ]; then
      echo "Installation script has already run. Not running again."
      return
    fi
    touch /tmp/install_started.lock

    echo "--- STARTING AUTOMATED NIXOS INSTALLATION ---"
    set -e # Exit immediately if a command fails

    # 1. Partition the disk for a UEFI system
    echo "Partitioning /dev/vda..."
    sfdisk /dev/vda <<EOF
    label: gpt
    ,1G,U,*
    ,,L
    EOF

    # 2. Format the filesystems
    echo "Formatting filesystems..."
    mkfs.fat -F 32 -n boot /dev/vda1
    mkfs.ext4 -L root /dev/vda2

    # 3. Mount the filesystems
    echo "Mounting filesystems..."
    mkdir -p /mnt
    mount /dev/disk/by-label/root /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot

    # 4. Clone your NixOS configuration from GitHub
    echo "Cloning nix-configs repository..."
    git clone https://github.com/trojas-gnister/nix-configs /mnt/etc/nixos

    # 5. Install NixOS using the 'blackspace' configuration from your flake
    echo "Installing NixOS from flake: /mnt/etc/nixos#blackspace"
    nixos-install --no-root-passwd --flake /mnt/etc/nixos#blackspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
