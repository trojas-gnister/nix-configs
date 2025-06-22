# modules/common/podman-quadlet-definitions/jellyseerr.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/jellyseerr.container" = {
    text = ''
      [Unit]
      Description=Jellyseerr Container
      After=network-online.target

      [Container]
      Image=fallenbagel/jellyseerr:latest
      ContainerName=jellyseerr
      Volume=${homeDir}/jellyseerr/config:/app/config
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=5055:5055

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

