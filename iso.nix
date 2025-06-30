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

    # 6. Clean up unnecessary files from the repository
    echo "Cleaning up configuration directory..."
    rm /mnt/etc/nixos/configuration.nix
    rm /mnt/etc/nixos/.gitignore

    # 7. Create a basic variables.nix for the new VM
    echo "Creating basic variables.nix..."
    cat > /mnt/etc/nixos/variables.nix <<'EOF'
    { config, lib, pkgs, ... }:
    {
      imports = [ ./lib/variables-module.nix ];

      variables = {
        packages = {
          system = [];
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
        };

        user = {
          name = "user";
          groups = [ "wheel" "audio" "video" ];
        };

        firewall = {
          openTCPPorts = [];
          openUDPPorts = [];
          openUDPPortRanges = [];
          trustedInterfaces = [];
        };
      };
    }
    EOF

    # 8. Install NixOS using the final, assembled configuration
    echo "Installing NixOS from flake: /mnt/etc/nixos#blackspace"
    nixos-install --no-root-passwd --impure --flake /mnt/etc/nixos#blackspace

    echo "--- INSTALLATION COMPLETE ---"
    echo "VM will now power off."
    poweroff
  '';
}
