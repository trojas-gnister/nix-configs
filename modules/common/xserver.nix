# modules/common/xserver.nix
{ config, lib, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = config.variables.user.name;
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

  home-manager.users.${config.variables.user.name} = {
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        terminal = "kitty";
        modifier = "Mod4";
        floating.modifier = "Mod4";
      };
      extraConfig = ''
        for_window [class="^.*"] border pixel 0
      '';
    };
  };
}
