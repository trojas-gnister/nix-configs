# modules/common/podman-quadlet-definitions/qbittorrent.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/qbittorrent.container" = {
    text = ''
      [Unit]
      Description=qBittorrent (via Gluetun)
      After=network-online.target
      Wants=gluetun.service

      [Container]
      Image=lscr.io/linuxserver/qbittorrent:latest
      ContainerName=qbittorrent
      PodmanArgs=--network=container:gluetun
      
      Volume=${homeDir}/qbittorrent/config:/config
      Volume=${homeDir}/qbittorrent/downloads:/downloads

      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}

      # Tell qBittorrent what port to expose internally and to announce to trackers
      Environment=WEBUI_PORT=8080           # ↳ internal UI port
      Environment=TORRENTING_PORT=51820 # ↳ forwarded peer port

      # Make the WebUI reachable on the host
      PublishPort=8080:8080                 # ↳ host:container mapping for WebUI

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

