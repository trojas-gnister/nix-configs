{ userName }:
{ config, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = userName;
    };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
      ];
    };
  };
}

