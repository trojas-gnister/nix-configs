# lib/variables-module.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.variables;
in {
  options.variables = {
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
