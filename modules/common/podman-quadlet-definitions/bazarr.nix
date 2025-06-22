# modules/common/podman-quadlet-definitions/bazarr.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/bazarr.container" = {
    text = ''
      [Unit]
      Description=Bazarr Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/bazarr:latest
      ContainerName=bazarr
      Volume=${homeDir}/bazarr/config:/config
      Volume=${homeDir}/media:/data
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=6767:6767

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

