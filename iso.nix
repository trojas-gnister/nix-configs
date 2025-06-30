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

    # 3. Clone your NixOS configuration from GitHub
    echo "Cloning nix-configs repository..."
    git clone https://github.com/trojas-gnister/nix-configs /mnt/etc/nixos

    # 4. Generate the hardware-specific configuration
    echo "Generating hardware configuration..."
    nixos-generate-config --root /mnt

    # 5. Prepare the final configuration directory
    echo "Preparing final configuration..."
    # Change into the repository directory
    cd /mnt/etc/nixos
    # Add the newly generated hardware configuration to the git index.
    git add hardware-configuration.nix

    # 6. Install NixOS using the 'blackspace' configuration from your flake
    echo "Installing NixOS from flake: .#blackspace"
    # Allow unfree packages (like steam) to be installed.
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake .#blackspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
