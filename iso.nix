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

    # Check for a "lock file" to ensure this script only runs once.
    if [ -f /tmp/install_started.lock ]; then
      echo "Installation script has already run. Not running again."
      return
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

    # 4. Generate the NixOS configuration for the new system
    echo "Generating target configuration.nix..."
    cat > /mnt/etc/nixos/configuration.nix <<'EOF'
    { config, pkgs, ... }:

    {
      imports = [
        ./hardware-configuration.nix
      ];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "nixos-vm";
      networking.useDHCP = true;

      services.openssh.enable = true;
      services.openssh.settings.PermitRootLogin = "prohibit-password";

      users.users.demo = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          # Add your SSH public key here if you have one
        ];
      };

      system.stateVersion = "24.11";
    }
    EOF

    # Generate the hardware config
    nixos-generate-config --root /mnt

    # 5. Install NixOS
    echo "Installing NixOS..."
    nixos-install --no-root-passwd

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
