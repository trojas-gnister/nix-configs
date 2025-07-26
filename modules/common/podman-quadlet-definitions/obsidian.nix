{ pkgs, config, lib, ... }:
{
  "containers/systemd/obsidian.container" = {
    text = ''
      [Unit]
      Description=Obsidian Container
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/obsidian:latest
      ContainerName=obsidian-quadlet
      PublishPort=3006:3000
      PublishPort=3007:3001
      Volume=obsidian-config:/config
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
