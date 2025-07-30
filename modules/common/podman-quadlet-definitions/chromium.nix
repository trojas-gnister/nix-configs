{ pkgs, config, lib, ... }:
{
  "containers/systemd/user/chromium.container" = {
    text = ''
      [Unit]
      Description=Chromium Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/chromium:latest
      ContainerName=chromium-quadlet
      PublishPort=3004:3001
      Volume=chromium-config:/config
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
