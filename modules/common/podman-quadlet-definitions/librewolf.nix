{ pkgs, config, lib, ... }:
{
  "containers/systemd/user/librewolf.container" = {
    text = ''
      [Unit]
      Description=LibreWolf Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/librewolf:latest
      ContainerName=librewolf-quadlet
      PublishPort=3001:3001
      Volume=librewolf-config:/config
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      ShmSize=1gb

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';
  };
}
