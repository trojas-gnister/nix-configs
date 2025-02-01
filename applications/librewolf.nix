{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.librewolf ];

  programs.librewolf = {
    enable = true;
    settings = {
      "ui.systemUsesDarkTheme" = 1;
    };
  };
}

