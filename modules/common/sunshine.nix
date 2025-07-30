{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sunshine
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };

  systemd.user.services.sunshine = {
    description = "Sunshine Game Streaming Server";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  home-manager.users.${config.variables.user.name} = {
    xdg.configFile."sunshine/sunshine.conf".text = ''
      sunshine_name = ${config.variables.networking.hostname}
      min_log_level = info
      upnp = on
      address_family = both
    '';
  };
}
