{ pkgs, config, lib, ... }:
{
  "containers/systemd/steamos.container" = {
    text = ''
      [Unit]
      Description=SteamOS Container
      Wants=network-online.target
      After=network-online.target

      [Container]
      ContainerName=steamos
      Image=lscr.io/linuxserver/steamos:latest

      PodmanArgs=--replace
      PodmanArgs=--device=/dev/dri
      PodmanArgs=--device=/dev/uinput:/dev/uinput:rw
      PodmanArgs=--security-opt=seccomp:unconfined
      PodmanArgs=--security-opt=apparmor:unconfined

      AddCapability=NET_ADMIN

      Environment=PUID=1001
      Environment=PGID=100
      Environment=TZ=${config.time.timeZone}
      Environment=DRINODE=/dev/dri/renderD128

      PublishPort=5000:3000
      PublishPort=27031-27036:27031-27036/udp
      PublishPort=27031-27036:27031-27036/tcp
      PublishPort=47984-47990:47984-47990/tcp
      PublishPort=48010:48010/tcp
      PublishPort=47998-48000:47998-48000/udp

      Volume=steamos-data:/config
      Volume=/dev/input:/dev/input:rw
      Volume=/run/udev/data:/run/udev/data:ro

      ShmSize=1gb

      [Service]
      Restart=unless-stopped
      TimeoutStartSec=600

      [Install]
      WantedBy=default.target
    '';
  };
}
