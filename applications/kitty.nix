{ userName }:
{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kitty ];


  home-manager.users = {
    "${userName}" = {
      programs = {
        kitty = {
          enable = true;
          extraConfig = ''
            background_opacity 0.70
          '';
        };
      };
      xsession.windowManager.i3.extraConfig = ''
        exec kitty
      '';
    };
  };
}

