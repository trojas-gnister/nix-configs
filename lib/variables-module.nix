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
        description = "List of system-wide package names to install.";
      };
      homeManager = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of package names to install for the user via Home Manager.";
      };
      unfree = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of unfree package names to allow.";
      };
    };
    steamdeck = {
      handheld = {
        enable = mkOption { type = types.bool; default = false; description = "Whether this is a handheld device"; };
        screenSize = mkOption { type = types.float; description = "Screen size in inches"; };
        resolution = {
          width = mkOption { type = types.int; description = "Screen width in pixels"; };
          height = mkOption { type = types.int; description = "Screen height in pixels"; };
        };
      };
      power = {
        tdp = mkOption { type = types.int; description = "Thermal Design Power in watts"; };
        battery = {
          capacity = mkOption { type = types.int; description = "Battery capacity in watt-hours"; };
          saveMode = mkOption { type = types.bool; default = false; description = "Enable battery saver mode"; };
        };
      };
    };
    networking = {
      staticIP = mkOption { type = types.str; description = "Static IP address for the host"; default = ""; };
      gateway = mkOption { type = types.str; description = "Gateway address"; default = ""; };
      netmask = mkOption { type = types.str; description = "Network mask"; default = ""; };
      hostname = mkOption { type = types.str; description = "Hostname"; };
    };
    ssh = {
      initrd = {
        port = mkOption { type = types.port; description = "SSH port for initrd"; default = 0; };
        hostKeyPath = mkOption { type = types.str; description = "Path to the SSH host key"; default = ""; };
        authorizedKeys = mkOption { type = types.listOf types.str; description = "Authorized SSH keys"; default = []; };
      };
    };
    user = {
      name = mkOption { type = types.str; description = "Primary user name"; };
      groups = mkOption { type = types.listOf types.str; description = "User groups"; default = []; };
    };
    firewall = {
      openTCPPorts = mkOption { type = types.listOf types.port; description = "Open TCP ports"; default = []; };
      openTCPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
        description = "Open TCP port ranges";
      };
      openUDPPorts = mkOption { type = types.listOf types.port; description = "Open UDP ports"; default = []; };
      openUDPPortRanges = mkOption {
        type = types.listOf (types.submodule {
          options = {
            from = mkOption { type = types.port; };
            to = mkOption { type = types.port; };
          };
        });
        default = [];
        description = "Open UDP port ranges";
      };
      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of trusted network interface names for the firewall.";
      };
    };
  };
}
