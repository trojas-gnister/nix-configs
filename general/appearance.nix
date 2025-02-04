{ userName, homeStateVersion }:
{ config, pkgs, ... }:
{
  environment.variables.GTK_THEME = "Adwaita:dark";
  home-manager.users = {
    "${userName}" = { pkgs, ... }: {
      home.stateVersion = homeStateVersion;
      services.picom.enable = true;

      xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';

      xsession.windowManager.i3 = {
        enable = true;
        config = {
          terminal = "kitty";
          modifier = "Mod4";
          floating = {
            modifier = "Mod4";
          };
        };
        extraConfig = ''
          for_window [class="^.*"] border pixel 0
        '';
      };
    };
  };
}

