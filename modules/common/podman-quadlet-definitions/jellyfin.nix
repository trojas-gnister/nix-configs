{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/jellyfin.container" = {
    text = ''
      [Unit]
      Description=Jellyfin Media Server
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/jellyfin:latest
      ContainerName=jellyfin
      Volume=${homeDir}/jellyfin/config:/config
      Volume=${homeDir}/media:/media
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=8096:8096

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

