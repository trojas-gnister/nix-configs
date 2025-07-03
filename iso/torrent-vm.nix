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

    # 1. Partition the disk
    echo "Partitioning /dev/vda..."
    sfdisk /dev/vda <<EOF
    label: gpt
    ,1G,U,*
    ,,L
    EOF
    partprobe /dev/vda
    sleep 2

    # 2. Format the filesystems
    echo "Formatting filesystems..."
    mkfs.fat -F 32 -n boot /dev/vda1
    mkfs.ext4 -F -L root /dev/vda2

    # Wait for udev to create the /dev/disk/by-label links
    echo "Waiting for udev to settle..."
    udevadm settle
    sleep 2

    # 3. Mount the filesystems
    echo "Mounting filesystems..."
    mkdir -p /mnt
    mount /dev/disk/by-label/root /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot

    # 4. Clone your NixOS configuration from GitHub
    echo "Cloning nix-configs repository..."
    cd 
    git clone https://github.com/trojas-gnister/nix-configs 
    cp -r ~/nix-configs/flake.nix ~/nix-configs/hosts ~/nix-configs/iso ~/nix-configs/lib ~/nix-configs/modules /mnt/etc/nixos

    # 5. Prepare the final configuration directory
    echo "Preparing final configuration..."
    # Generate the hardware-specific configuration
    nixos-generate-config --root /mnt
    # Change into the repository directory
    cd /mnt/etc/nixos
    # 6. Install NixOS using the 'blackspace' configuration from your flake
    echo "Installing NixOS from flake: .#krawlspace"
    # Allow unfree packages (like steam) to be installed.
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake .#krawlspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
