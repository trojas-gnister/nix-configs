# modules/common/podman-quadlet-definitions/librewolf-https.nix
{ pkgs, config, lib, ... }:
{
  "containers/systemd/user/librewolf.container" = {
    text = ''
      [Unit]
      Description=LibreWolf Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/librewolf:latest
      ContainerName=librewolf-https
      
      Volume=librewolf-config:/config
      
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      Environment=CUSTOM_PORT=3000
      Environment=CUSTOM_HTTPS_PORT=3001
      Environment=TITLE=LibreWolf Browser
      
      PublishPort=8001:3000
      PublishPort=8002:3001
      
      ShmSize=1gb

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}
