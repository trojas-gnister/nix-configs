# modules/common/podman-quadlet-definitions/nextcloud.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/nextcloud.container" = {
    text = ''
      [Unit]
      Description=Nextcloud Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/nextcloud:latest
      ContainerName=nextcloud
      Volume=${homeDir}/nextcloud/config:/config
      Volume=${homeDir}/nextcloud/data:/data
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      PublishPort=443:443

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

