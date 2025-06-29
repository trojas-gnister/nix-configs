{ config, lib, pkgs, ... }:

{
  imports = [
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  programs.adb.enable = true;
  networking.hostName = config.variables.networking.hostname;
  system.stateVersion = "24.11";
  hardware = {
    asahi.peripheralFirmwareDirectory = ../firmware;
    graphics.enable = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };


  };
}
