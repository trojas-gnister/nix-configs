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
    rsync
  ];

  environment.etc."profile.d/install.sh".text = ''
    if [ -f /tmp/install_started.lock ]; then
      echo "Installation script has already run. Not running again."
      exit 0
    fi
    touch /tmp/install_started.lock

    echo "--- STARTING AUTOMATED NIXOS INSTALLATION ---"
    set -e

    echo "Partitioning and formatting /dev/vda for BIOS..."
    sfdisk /dev/vda <<EOF
    label: dos
    ,,L,*
    EOF
    partprobe /dev/vda
    sleep 2
    mkfs.ext4 -L nixos /dev/vda1

    echo "Waiting for udev to create disk labels..."
    udevadm settle
    sleep 2

    echo "Mounting filesystems..."
    mkdir -p /mnt
    mount /dev/disk/by-label/nixos /mnt

    echo "Generating hardware configuration..."
    nixos-generate-config --root /mnt

    echo "Cloning nix-configs repository..."
    git clone https://github.com/trojas-gnister/nix-configs /tmp/nix-configs

    echo "Copying repository files into place..."
    rsync -a --exclude 'hardware-configuration.nix' --exclude '.git' --exclude 'configuration.nix' /tmp/nix-configs/ /mnt/etc/nixos/

    echo "Cleaning up temporary clone..."
    rm -rf /tmp/nix-configs

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
          groups = [ "wheel" "audio" "video" "networkmanager" "podman" ];
        };

        firewall = {
          openTCPPorts = [ 3001 3004 ];
          openUDPPorts = [ ];
        };
      };
    }
    EOF

    echo "Installing NixOS from flake: /mnt/etc/nixos#browserspace"
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake /mnt/etc/nixos#browserspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
