# modules/common/podman-quadlet-definitions/sonarr.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/sonarr.container" = {
    text = ''
      [Unit]
      Description=Sonarr Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/sonarr:latest
      ContainerName=sonarr
      Volume=${homeDir}/sonarr/config:/config
      Volume=${homeDir}/media:/data
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=8989:8989

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

