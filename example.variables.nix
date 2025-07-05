{ config, lib, pkgs, ... }:

{
  imports = [ ./lib/variables-module.nix ];

  variables = {
    packages = {
      system = [
        "wget"
        "qemu-utils"
      ];
      homeManager = [
        "btop"
        "neovim"
      ];
      unfree = [
        "steam"
      ];
    };

    networking = {
      hostname = "your-hostname";
    };

    ssh = {
      initrd = {
        port = 2222;
        hostKeyPath = "/boot/dropbear_host_rsa_key";
        authorizedKeys = [
          "ssh-ed25519 AAAA... your-key-name@host"
        ];
      };
    };

    user = {
      name = "your-username";
      password = "your-password";
      groups = [ "podman" "wheel" "audio" "libvirtd" ];
    };

    firewall = {
      openTCPPorts = [ 80 443 ];
      openTCPPortRanges = [
        { from = 8000; to = 8010; }
      ];
      openUDPPorts = [ 51820 ];
      openUDPPortRanges = [
        { from = 60000; to = 61000; }
      ];
      trustedInterfaces = [ ];
    };

    # --------------------------------------------------------------------
    # Use the VM generator to declare your virtual machines.
    # For each VM, you must create a disk image, e.g.:
    # qemu-img create -f qcow2 /path/to/disk.qcow2 50G
    # --------------------------------------------------------------------
    vms = {
      "main-server" = {
        enable = true;
        uuid = "a1b2c3d4-e5f6-7890-1234-567890abcdef";
        memorySize = 16;
        diskPath = "/var/lib/libvirt/images/main-server.qcow2";
        
        # To install, set firstBoot and specify an ISO from your /iso directory
        firstBoot = true;
        isoName = "nixos-installer"; # Corresponds to /iso/nixos-installer.nix
      };

      "testing-vm" = {
        enable = true;
        uuid = "f1e2d3c4-b5a6-9870-1234-abcdef123456";
        memorySize = 8;
        diskPath = "/var/lib/libvirt/images/testing-vm.qcow2";

        # After installation, set firstBoot to false and rebuild.
        firstBoot = false;
        isoName = null;
      };
    };
  };
}
