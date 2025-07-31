{ pkgs, config, lib, ... }:
{
  "containers/systemd/steam-headless.container" = {
    text = ''
      [Unit]
      Description=Steam Headless Container
      Wants=network-online.target
      After=network-online.target

      [Container]
      ContainerName=steam-headless
      Image=josh5/steam-headless:latest

      PodmanArgs=--replace
      # GPU access - Intel/AMD GPU support
      PodmanArgs=--device=/dev/dri
      # Controller/Gamepad support - run as root to access uinput
      PodmanArgs=--device=/dev/uinput
      # Audio device access (PulseAudio)
      PodmanArgs=--device=/dev/snd
      # Security options for GPU and device access
      PodmanArgs=--security-opt=seccomp:unconfined
      PodmanArgs=--security-opt=apparmor:unconfined
      # Run with privileges needed for uinput access
      PodmanArgs=--privileged

      # Required capabilities
      AddCapability=NET_ADMIN
      AddCapability=SYS_ADMIN

      # Environment variables - run as root for device access
      Environment=PUID=0
      Environment=PGID=0
      Environment=TZ=${config.time.timeZone}
      Environment=DRINODE=/dev/dri/renderD128
      Environment=MODE=primary
      Environment=WEB_UI_MODE=vnc
      Environment=ENABLE_VNC_AUDIO=true
      Environment=DISPLAY=:0
      Environment=USER_LOCALES=en_US.UTF-8 UTF-8
      Environment=UDEV=1

      # Port mappings
      # Web UI (noVNC)
      PublishPort=8083:8083
      # VNC server
      PublishPort=5900:5900
      # Steam Remote Play ports
      PublishPort=27031-27036:27031-27036/udp
      PublishPort=27031-27036:27031-27036/tcp
      # Moonlight streaming ports
      PublishPort=47984-47990:47984-47990/tcp
      PublishPort=48010:48010/tcp
      PublishPort=47998-48000:47998-48000/udp

      # Volume mounts
      Volume=steam-headless-config:/home/default
      Volume=/tmp/.X11-unix:/tmp/.X11-unix:rw
      Volume=/dev/input:/dev/input:rw
      Volume=/run/udev/data:/run/udev/data:ro
      # Optional games directory - uncomment if you have one
      # Volume=/mnt/games:/mnt/games:rw

      # Shared memory for better performance
      ShmSize=2gb

      [Service]
      Restart=unless-stopped
      TimeoutStartSec=900

      [Install]
      WantedBy=default.target
    '';
  };
}