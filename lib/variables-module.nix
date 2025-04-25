{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.variables;
in {
  options.variables = {
      steamdeck = {
      handheld = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this is a handheld device";
        };
        screenSize = mkOption {
          type = types.float;
          description = "Screen size in inches";
        };
        resolution = {
          width = mkOption {
            type = types.int;
            description = "Screen width in pixels";
          };
          height = mkOption {
            type = types.int;
            description = "Screen height in pixels";
          };
        };
      };
      power = {
        tdp = mkOption {
          type = types.int;
          description = "Thermal Design Power in watts";
        };
        battery = {
          capacity = mkOption {
            type = types.int;
            description = "Battery capacity in watt-hours";
          };
          saveMode = mkOption {
            type = types.bool;
            default = false;
            description = "Enable battery saver mode";
          };
        };
      };
    };
    networking = {
      staticIP = mkOption {
        type = types.str;
        description = "Static IP address for the host";
      };
      gateway = mkOption {
        type = types.str;
        description = "Gateway address";
      };
      netmask = mkOption {
        type = types.str;
        description = "Network mask";
      };
      hostname = mkOption {
        type = types.str;
        description = "Hostname";
      };
      leviathan = {
        hostname = mkOption {
          type = types.str;
          description = "Steam Deck hostname";
        };
      };
    };
    ssh = {
      initrd = {
        port = mkOption {
          type = types.int;
          description = "SSH port for initrd";
        };
        hostKeyPath = mkOption {
          type = types.str;
          description = "Path to the SSH host key";
        };
        authorizedKeys = mkOption {
          type = types.listOf types.str;
          description = "Authorized SSH keys";
        };
      };
    };
    user = {
      name = mkOption {
        type = types.str;
        description = "Primary user name";
      };
      groups = mkOption {
        type = types.listOf types.str;
        description = "User groups";
      };
    };
    firewall = {
      openTCPPorts = mkOption {
        type = types.listOf types.int;
        description = "Open TCP ports";
      };
      openUDPPorts = mkOption {
        type = types.listOf types.int;
        description = "Open UDP ports";
      };
      openUDPPortRanges = mkOption {
        type = types.listOf (types.attrsOf types.int);
        description = "Open UDP port ranges";
      };
    };
  };
}
