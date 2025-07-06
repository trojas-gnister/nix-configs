{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.variables;
in {
  options.variables = {
    packages = {
      system = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      homeManager = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      unfree = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
    steamdeck = {
      handheld = {
        enable = mkOption { type = types.bool; default = false; };
        screenSize = mkOption { type = types.float; };
        transform = mkOption { type = types.str; default = "0"; };
        resolution = {
          width = mkOption { type = types.int; };
          height = mkOption { type = types.int; };
        };
      };
      power = {
        tdp = mkOption { type = types.int; };
        battery = {
          capacity = mkOption { type = types.int; };
          saveMode = mkOption { type = types.bool; default = false; };
        };
      };
    };
    vms = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "NixOS VM named ${name}";
          diskPath = mkOption {
            type = types.str;
            description = "Path to the qcow2 disk image for the VM.";
          };
          diskSize = mkOption {
            type = types.int;
            default = 32;
            description = "Disk size in GiB for the new VM image.";
          };
          memorySize = mkOption {
            type = types.int;
            default = 4;
            description = "RAM size in GiB.";
          };
          uuid = mkOption {
            type = types.str;
            description = "Unique UUID for the VM.";
          };
          ip = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Manually updated IP address of the VM for port forwarding.";
          };
          isoName = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "The name of the ISO build to use for installation.";
          };
          firstBoot = mkOption {
            type = types.bool;
            default = false;
            description = "If true, attach the installer ISO for initial installation.";
          };
          forwardedPorts = mkOption {
            type = types.listOf (types.submodule {
              options = {
                proto = mkOption {
                  type = types.enum [ "tcp" "udp" ];
                  description = "Protocol of the port to forward.";
                };
                sourcePort = mkOption {
                  type = types.port;
                  description = "Port on the host to listen on.";
                };
                destinationPort = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                  description = "Port on the guest to forward to (defaults to sourcePort).";
                };
              };
            });
            default = [];
            description = "A list of ports to forward from the host to this VM.";
          };
          firewall = mkOption {
            type = types.submodule {
              options = {
                openTCPPorts = mkOption { type = types.listOf types.port; default = []; };
                openUDPPorts = mkOption { type = types.listOf types.port; default = []; };
              };
            };
            default = {};
          };
        };
      }));
      default = {};
      description = "Declarative definition of virtual machines.";
    };
    networking = {
      hostname = mkOption { type = types.str; default = "hostname"; };
      externalInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The primary external-facing network interface for NAT.";
      };
    };
    ssh = {
      initrd = {
        port = mkOption { type = types.port; default = 0; };
        hostKeyPath = mkOption { type = types.str; default = ""; };
        authorizedKeys = mkOption { type = types.listOf types.str; default = []; };
      };
    };
    user = {
      name = mkOption { type = types.str; default = "user"; };
      password = mkOption { type = types.str; default = "password"; };
      groups = mkOption { type = types.listOf types.str; default = [ "wheel" "audio" ]; };
    };
    firewall = {
      openTCPPorts = mkOption { type = types.listOf types.port; default = []; };
      openTCPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
      };
      openUDPPorts = mkOption { type = types.listOf types.port; default = []; };
      openUDPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
      };
      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
  };
}
