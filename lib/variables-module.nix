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
    vm = {
      password = mkOptions { type = types.str; };
      };
    networking = {
      staticIP = mkOption { type = types.str; default = ""; };
      gateway = mkOption { type = types.str; default = ""; };
      netmask = mkOption { type = types.str; default = ""; };
      hostname = mkOption { type = types.str; default = "hostname"; };
    };
    ssh = {
      initrd = {
        port = mkOption { type = types.port; default = 0; };
        hostKeyPath = mkOption { type = types.str; default = ""; };
        authorizedKeys = mkOption { type = types.listOf types.str; default = []; };
      };
    };
    user = {
      name = mkOption { type = types.str; default = "user" };
      password = mkOptions { type = types.str; default = "password"; };
      groups = mkOption { type = types.listOf types.str; default = [ "wheel" "audio" ];  };
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

