# modules/common/podman-quadlet-definitions/prowlarr.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/prowlarr.container" = {
    text = ''
      [Unit]
      Description=Prowlarr Container (via Gluetun)
      After=network-online.target
      Wants=gluetun.service

      [Container]
      Image=lscr.io/linuxserver/prowlarr:latest
      ContainerName=prowlarr
      PodmanArgs=--network=container:gluetun
      Volume=${homeDir}/prowlarr/config:/config
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=9696:9696

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

