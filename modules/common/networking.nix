{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  environment.variables.GTK_THEME = "Adwaita:dark";
}
