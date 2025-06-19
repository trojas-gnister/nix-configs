{ config, lib, pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  home-manager.users.${config.variables.user.name} = {
    xdg.desktopEntries."gs-launcher" = {
      name = "Gamescope Steam";
      comment = "Launch Steam in a Gamescope session";
      exec = "gs-launcher";
      icon = "steam";
      terminal = false;
      categories = [ "Game" ];
    };
  };
}
