{ config, lib, pkgs, ... }:
{
  imports = [ ./lib/variables-module.nix ];
  
  variables = {
    # --------------------------------------------------------------------
    # PACKAGE MANAGEMENT
    # System packages are installed globally, homeManager packages are 
    # installed per-user, unfree packages require explicit declaration
    # --------------------------------------------------------------------
    packages = {
      system = [
        "wget"
        "qemu-utils"
        "git"
        "neovim"
        "tmux"
        "htop"
        # Add system-wide packages here
      ];
      homeManager = [
        "btop"
        "firefox"
        "chromium"
        "virt-manager"
        "kitty"
        # Add user-specific packages here
      ];
      unfree = [
        "steam"
        "discord"
        "spotify"
        # Add unfree packages that you want to allow
      ];
    };

    # --------------------------------------------------------------------
    # STEAMDECK CONFIGURATION (optional, only for Steam Deck deployments)
    # Configure handheld-specific settings and power management
    # --------------------------------------------------------------------
    steamdeck = {
      handheld = {
        enable = false;  # Set to true for Steam Deck
        screenSize = 7.0;  # Screen size in inches
        transform = "0";   # Display rotation: "0", "90", "180", "270"
        resolution = {
          width = 1280;
          height = 800;
        };
      };
      power = {
        tdp = 15;  # Thermal Design Power in watts
        battery = {
          capacity = 5313;  # mAh
          saveMode = false; # Enable power saving mode
        };
      };
    };

    # --------------------------------------------------------------------
    # NETWORKING CONFIGURATION
    # Configure hostname and network interfaces for NAT forwarding
    # --------------------------------------------------------------------
    networking = {
      hostname = "your-hostname";
      externalInterface = "enp6s0";  # Main network interface (ethernet/wifi)
      internalInterfaces = [ "virbr0" ];  # Internal bridges (usually libvirt)
    };

    # --------------------------------------------------------------------
    # SSH CONFIGURATION
    # Configure SSH access during boot (initrd) for remote unlocking
    # --------------------------------------------------------------------
    ssh = {
      initrd = {
        port = 2222;  # SSH port during boot
        hostKeyPath = "/boot/dropbear_host_rsa_key";  # SSH host key location
        authorizedKeys = [
          "ssh-ed25519 AAAA... your-key-name@host"
          # Add your SSH public keys here for initrd access
        ];
      };
    };

    # --------------------------------------------------------------------
    # USER CONFIGURATION
    # Define the primary user account and group memberships
    # --------------------------------------------------------------------
    user = {
      name = "your-username";
      password = "your-password";  # Consider using hashedPassword instead
      groups = [ 
        "podman"        # Container management
        "wheel"         # sudo access
        "audio"         # Audio devices
        "libvirtd"      # VM management
        "networkmanager" # Network configuration
        "video"         # Video devices
        "input"         # Input devices
        "render"        # GPU rendering
        # Add additional groups as needed
      ];
    };

    # --------------------------------------------------------------------
    # FIREWALL CONFIGURATION
    # Define ports and interfaces for network access
    # --------------------------------------------------------------------
    firewall = {
      openTCPPorts = [ 
        22    # SSH
        80    # HTTP
        443   # HTTPS
        # Add specific TCP ports here
      ];
      openTCPPortRanges = [
        { from = 8000; to = 8010; }  # Web development ports
        # Add port ranges here
      ];
      openUDPPorts = [ 
        51820  # WireGuard VPN
        # Add specific UDP ports here
      ];
      openUDPPortRanges = [
        { from = 60000; to = 61000; }  # Dynamic port range
        # Add UDP port ranges here
      ];
      trustedInterfaces = [ 
        "wg0"    # WireGuard interface
        # Add trusted network interfaces here
      ];
    };

    # --------------------------------------------------------------------
    # VIRTUAL MACHINE CONFIGURATION
    # Use the VM generator to declare your virtual machines.
    # 
    # IMPORTANT WORKFLOW FOR NEW VMs:
    # 1. Create VM with ip = null (no port forwarding yet)
    # 2. Deploy and install VM
    # 3. Check actual IP with: virsh domifaddr <vm-name>
    # 4. Update ip field with real IP and rebuild
    # 5. Port forwarding rules will be created automatically
    # 
    # For each VM, you must create a disk image first:
    # qemu-img create -f qcow2 /path/to/disk.qcow2 50G
    # --------------------------------------------------------------------
    vms = {
      "main-server" = {
        enable = true;
        uuid = "a1b2c3d4-e5f6-7890-1234-567890abcdef";  # Generate with uuidgen
        memorySize = 16;  # RAM in GB
        diskPath = "/var/lib/libvirt/images/main-server.qcow2";
        diskSize = 50;    # Disk size in GB (only used when creating new disk)
        
        # IP Configuration - LEAVE AS null FOR NEW VMs
        ip = null;  # Set to null initially, update after discovering real IP
        
        # Installation Configuration
        firstBoot = true;  # Set to true for initial installation
        isoName = "nixos-installer"; # Corresponds to /iso/nixos-installer.nix
        
        # Port Forwarding (only works when ip is set)
        firewall = {
          openTCPPorts = [ 80 443 ];  # Ports to forward from host
          openUDPPorts = [ ];         # UDP ports to forward
        };
      };
      
      "testing-vm" = {
        enable = true;
        uuid = "f1e2d3c4-b5a6-9870-1234-abcdef123456";
        memorySize = 8;
        diskPath = "/var/lib/libvirt/images/testing-vm.qcow2";
        diskSize = 32;
        
        # After installation workflow:
        ip = "192.168.122.150";  # Update with actual DHCP IP after installation
        firstBoot = false;       # Set to false after successful installation
        isoName = null;          # Remove ISO after installation
        
        firewall = {
          openTCPPorts = [ 8080 3000 ];
          openUDPPorts = [ ];
        };
      };
      
      # Example: Disabled VM (for reference)
      "old-vm" = {
        enable = false;  # Disabled VMs are ignored
        uuid = "12345678-1234-1234-1234-123456789abc";
        memorySize = 4;
        diskPath = "/var/lib/libvirt/images/old-vm.qcow2";
        # ... other settings don't matter when enable = false
      };
    };

    # --------------------------------------------------------------------
    # WIREGUARD VPN CONFIGURATION (optional)
    # Path to WireGuard client configuration file
    # --------------------------------------------------------------------
    wireguard = {
      clientConfigPath = "/path/to/wg0-client.conf";
      # Set to empty string "" to disable WireGuard
    };
  };
}
