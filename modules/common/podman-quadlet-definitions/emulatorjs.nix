{ pkgs, config, lib, ... }:
{
  "containers/systemd/emulatorjs.container" = {
    text = ''
      [Unit]
      Description=EmulatorJS Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/emulatorjs:latest
      ContainerName=emulatorjs-quadlet
      PublishPort=3000:3000
      PublishPort=8081:80
      PublishPort=4001:4001
      Volume=emulatorjs-config:/config
      Volume=emulatorjs-data:/data
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}

      [Service]
      Restart=always

      [Install]
      WantedBy=default.target
    '';
  };
}
