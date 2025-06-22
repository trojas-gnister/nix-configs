{ config, lib, pkgs, ... }:

{
  # This module imports the option definitions that we created.
  imports = [ ./lib/variables-module.nix ];

  # This section sets values for the custom variables defined in
  # lib/variables-module.nix. These control the host system's configuration.
  variables = {

    # Default packages to install on the host system.
    packages = {
      # Installed system-wide for all users.
      system = [
        "wget"
        "qemu"
        "qemu-utils"
        "pciutils"
      ];
      # Installed only for the primary user via Home Manager.
      homeManager = [
        "virt-manager"
        "btop"
        "neovim"
      ];
      # A list of unfree packages to allow. Requires unfree.nix module.
      unfree = [
        "steam"
      ];
    };

    # (Optional) Settings specific to a Steam Deck device.
    # steamdeck = {
    #   handheld.enable = true;
    #   ...
    # };

    # Networking configuration for the host system.
    networking = {
      # Example: "nixos-desktop"
      hostname = "your-hostname";
      # Example: "192.168.1.100"
      staticIP = "your.static.ip.here";
      # Example: "192.168.1.1"
      gateway = "your.gateway.ip.here";
      # Example: "255.255.255.0"
      netmask = "your.netmask.here";
    };

    # Configuration for unlocking the system via SSH during early boot (initrd).
    ssh = {
      initrd = {
        port = 2222;
        hostKeyPath = "/boot/dropbear_host_rsa_key";
        # A list of public SSH keys that are allowed to log in.
        authorizedKeys = [
          "ssh-ed25519 AAAA... your-key-name@host"
        ];
      };
    };

    # Primary user account settings for the host machine.
    user = {
      # The main username for the system.
      name = "your-username";
      # A list of groups to add the user to.
      groups = [ "podman" "wheel" "audio" "libvirtd" ];
    };

    # Host firewall settings.
    firewall = {
      openTCPPorts = [ 80 443 ];
      openTCPPortRanges = [
        { from = 8000; to = 8010; }
      ];
      openUDPPorts = [ 51820 ];
      openUDPPortRanges = [
        { from = 60000; to = 61000; }
      ];
      # List of network interfaces to trust, e.g., "enp6s0"
      trustedInterfaces = [ ];
    };
  };

  # --------------------------------------------------------------------
  # Use the VM generator to declare your virtual machines.
  # For each VM defined here, you must first create a disk image, e.g.:
  # qemu-img create -f qcow2 /path/to/disk.qcow2 50G
  # --------------------------------------------------------------------
  virtualisation.nixvirt.vms = {

    # --- EXAMPLE 1: Standard Storage Location ---
    # This VM uses the default libvirt storage path. No special permissions are needed.
    "standard-vm" = {
      enable = true;
      uuid = "f1e2d3c4-b5a6-9870-1234-abcdef123456";
      memorySize = 8;
      diskPath = "/var/lib/libvirt/images/standard-vm.qcow2";
    };

    # --- EXAMPLE 2: Custom Storage Location (e.g., another drive) ---
    # IMPORTANT: When using a custom diskPath like this, you MUST add a security
    # rule to your host's configuration (e.g., hosts/pc.nix or hosts/steamdeck.nix)
    # to grant libvirt permission to access it. Example rule:
    #
    #   security.apparmor.policies."libvirtd".rules = [
    #     "/path/to/your/vms/** rwk,"
    #   ];
    #
    "custom-storage-vm" = {
      enable = true;
      # Generate with the `uuidgen` command
      uuid = "a1b2c3d4-e5f6-7890-1234-567890abcdef";
      # RAM size in GiB
      memorySize = 16;
      # Path to the virtual disk on a separate drive
      diskPath = "/path/to/your/vms/custom-storage-vm.qcow2";
    };
  };
}
