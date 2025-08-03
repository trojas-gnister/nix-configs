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
      PodmanArgs=--ulimit nofile=1024:524288
      PodmanArgs=--cap-add=NET_ADMIN,SYS_ADMIN,SYS_NICE
      PodmanArgs=--network=host
      PodmanArgs=--hostname=steam-headless
      PodmanArgs=--add-host=steam-headless:127.0.0.1
      # GPU access - Intel/AMD GPU support
      PodmanArgs=--device=/dev/dri
      # Controller/Gamepad support with read/write access
      PodmanArgs=--device=/dev/uinput:/dev/uinput:rw
      # Audio device access (PulseAudio)
      PodmanArgs=--device=/dev/snd
      # Fuse device
      PodmanArgs=--device=/dev/fuse:/dev/fuse
      # Security options for GPU and device access
      PodmanArgs=--security-opt=seccomp:unconfined
      PodmanArgs=--security-opt=apparmor:unconfined

      # Environment variables
      Environment=PUID=1001
      Environment=PGID=100
      Environment=TZ=${config.time.timeZone}
      Environment=UMASK=000
      Environment=DRINODE=/dev/dri/renderD128
      Environment=MODE=primary
      Environment=WEB_UI_MODE=vnc
      Environment=ENABLE_VNC_AUDIO=true
      Environment=DISPLAY=:0
      Environment=USER_LOCALES=en_US.UTF-8 UTF-8
      Environment=UDEV=1
      Environment=ENABLE_EVDEV_INPUTS=true
      Environment=FORCE_X11_DUMMY_CONFIG=false
      Environment=ENABLE_STEAM=true
      Environment=ENABLE_SUNSHINE=false

      # Port mappings (with host network, PublishPort not needed, but for documentation)
      # Web UI (noVNC): 8083
      # VNC server: 5900
      # Steam Remote Play: 27031-27036 tcp/udp
      # Moonlight: 47984-47990 tcp, 48010 tcp, 47998-48000 udp

      # Volume mounts
      Volume=steam-headless-config:/home/default
      Volume=/dev/input:/dev/input:rw
      Volume=/run/udev/data:/run/udev/data:ro
      Volume=/home/${config.variables.user.name}/steam-headless-overlay/etc/cont-init.d:/etc/cont-init.d:rw
      # Optional games directory - uncomment if you have one
      # Volume=/mnt/games:/mnt/games:rw

      # Shared memory for better performance
      ShmSize=2gb

      [Service]
      Restart=always
      TimeoutStartSec=900

      [Install]
      WantedBy=default.target
    '';
  };
}
