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

    echo "Mounting filesystems..."
    mkdir -p /mnt
    mount /dev/disk/by-label/root /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot

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
          groups = [ "wheel" "audio" "video" "networkmanager" "libvirtd" ];
        };
      };
    }
    EOF

    echo "Installing NixOS from flake: /mnt/etc/nixos#krawlspace"
    export NIXPKGS_ALLOW_UNFREE=1
    nixos-install --no-root-passwd --impure --flake /mnt/etc/nixos#krawlspace

    echo "--- INSTALLATION COMPLETE ---"
  '';
}
