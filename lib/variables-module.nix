{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.variables;
in {
  options.variables = {
    # Package management options
    packages = {
      # System-wide packages installed via environment.systemPackages
      system = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      # Packages managed by home-manager for user environments
      homeManager = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      # List of unfree packages to allow
      unfree = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
    
    # Steam Deck specific configuration options
    steamdeck = {
      handheld = {
        # Enable Steam Deck handheld mode optimizations
        enable = mkOption { type = types.bool; default = false; };
        # Screen size for handheld devices
        screenSize = mkOption { type = types.float; };
        # Display transform setting (rotation)
        transform = mkOption { type = types.str; default = "0"; };
        # Screen resolution configuration
        resolution = {
          width = mkOption { type = types.int; };
          height = mkOption { type = types.int; };
        };
      };
      power = {
        # Thermal design power setting
        tdp = mkOption { type = types.int; };
        battery = {
          # Battery capacity in mAh
          capacity = mkOption { type = types.int; };
          # Enable battery save mode
          saveMode = mkOption { type = types.bool; default = false; };
        };
      };
    };
    
    # Virtual machine configuration
    vms = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          # Enable this VM definition
          enable = mkEnableOption "NixOS VM named ${name}";
          # Path to qcow2 disk image
          diskPath = mkOption {
            type = types.str;
            description = "Path to the qcow2 disk image for the VM.";
          };
          # Disk size in GiB for new VM images
          diskSize = mkOption {
            type = types.int;
            default = 32;
            description = "Disk size in GiB for the new VM image.";
          };
          # RAM allocation in GiB
          memorySize = mkOption {
            type = types.int;
            default = 4;
            description = "RAM size in GiB.";
          };
          # Unique identifier for the VM
          uuid = mkOption {
            type = types.str;
            description = "Unique UUID for the VM.";
          };
          # Static IP address for port forwarding
          ip = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Manually updated IP address of the VM for port forwarding.";
          };
          # ISO image name for installation
          isoName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "The name of the ISO build to use for installation.";
          };
          # Attach installer ISO on first boot
          firstBoot = mkOption {
            type = types.bool;
            default = false;
            description = "If true, attach the installer ISO for initial installation.";
          };
          # Firewall configuration for the VM
          firewall = mkOption {
            type = types.submodule {
              options = {
                openTCPPorts = mkOption { type = types.listOf types.port; default = []; };
                openUDPPorts = mkOption { type = types.listOf types.port; default = []; };
              };
            };
            default = {};
          };
          # Number of virtual CPUs
          vcpuCount = mkOption {
            type = types.int;
            default = 4;
            description = "Number of vCPUs for the VM.";
          };
          # PCI devices for passthrough
          pciDevices = mkOption {
            type = types.listOf types.str;
            default = [];
            example = [ "0000:03:00.0" "0000:03:00.1" ];
            description = "Full PCI addresses to passthrough (e.g., '0000:03:00.0').";
          };
          # CPU pinning configuration
          cpuPinning = mkOption {
            type = types.str;
            default = "";
            example = "8-23";
            description = "CPU pinning range for vCPUs (e.g., '8-23').";
          };
        };
      }));
      default = {};
      description = "Declarative definition of virtual machines.";
    };
    
    # Network configuration options
    networking = {
      # System hostname
      hostname = mkOption { type = types.str; default = "hostname"; };
      # External network interface for NAT
      externalInterface = mkOption {
        type = types.str;
        default = "eth0";
        description = "The external network interface for NAT (e.g., wlo1 for WiFi).";
      };
      # Internal network interfaces for NAT
      internalInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of internal network interfaces for NAT (e.g., [ 'virbr0' ] for libvirt bridge).";
      };
    };
    
    # SSH configuration
    ssh = {
      initrd = {
        # SSH port for initrd access
        port = mkOption { type = types.port; default = 0; };
        # Path to SSH host key for initrd
        hostKeyPath = mkOption { type = types.str; default = ""; };
        # Authorized SSH keys for initrd access
        authorizedKeys = mkOption { type = types.listOf types.str; default = []; };
      };
    };
    
    # User account configuration
    user = {
      # Username for the primary user
      name = mkOption { type = types.str; default = "user"; };
      # Password for the primary user
      password = mkOption { type = types.str; default = "password"; };
      # Groups the user should belong to
      groups = mkOption { type = types.listOf types.str; default = [ "wheel" "audio" ]; };
    };
    
    # Firewall configuration
    firewall = {
      # Individual TCP ports to open
      openTCPPorts = mkOption { type = types.listOf types.port; default = []; };
      # TCP port ranges to open
      openTCPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
      };
      # Individual UDP ports to open
      openUDPPorts = mkOption { type = types.listOf types.port; default = []; };
      # UDP port ranges to open
      openUDPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
      };
      # Network interfaces to trust completely
      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
    
    # WireGuard VPN configuration
    wireguard = {
      # Path to WireGuard client configuration file
      clientConfigPath = mkOption {
        type = types.str;
        default = "";
      };
    };
    
    # VFIO PCI passthrough configuration
    vfio = {
      # Enable VFIO support
      enable = mkEnableOption "VFIO PCI passthrough setup";
      # PCI device IDs to bind to VFIO driver
      pciIds = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "10de:1c03" "10de:10f1" ];
        description = "PCI device IDs to bind to VFIO (format: vendor:product). Include all functions (e.g., GPU video + audio).";
      };
      # Kernel modules to prevent from loading
      blacklistedDrivers = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "nouveau" "nvidia" "nvidiafb" "nvidia_drm" ];
        description = "Kernel modules to blacklist to prevent them from claiming the passthrough devices.";
      };
      # CPU cores to isolate for VM use
      isolatedCores = mkOption {
        type = types.str;
        default = "";
        example = "4-7";
        description = "CPU cores to isolate for VFIO use (format for isolcpus kernel param, e.g., '4-7' or '2,3,6,7'). Leave empty to disable.";
      };
    };
    
    # Wallpaper configuration
    wallpaper = {
      # Path to wallpaper image file
      path = mkOption {
        type = types.str;
        default = "";
        description = "Path to the wallpaper image file.";
      };
    };
  };
}
