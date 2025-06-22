# modules/common/podman-quadlet-definitions/radarr.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/radarr.container" = {
    text = ''
      [Unit]
      Description=Radarr Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/radarr:latest
      ContainerName=radarr
      Volume=${homeDir}/radarr/config:/config
      Volume=${homeDir}/media:/data
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=7878:7878

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

