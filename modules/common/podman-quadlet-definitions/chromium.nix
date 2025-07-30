{ pkgs, config, lib, ... }:
{
  "containers/systemd/user/chromium.container" = {
    text = ''
      [Unit]
      Description=Chromium Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/chromium:latest
      ContainerName=chromium-https
      
      Volume=chromium-config:/config
      
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      Environment=CUSTOM_PORT=3000
      Environment=CUSTOM_HTTPS_PORT=3001
      Environment=TITLE=Chromium Browser
      
      PublishPort=8003:3000
      PublishPort=8004:3001
      
      ShmSize=1gb

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

