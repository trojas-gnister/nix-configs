{ pkgs, config, lib, ... }:
{
  "containers/systemd/wolf.container" = {
    text = ''
      [Unit]
      Description=Wolf Streaming Server
      Wants=network-online.target
      After=network-online.target

      [Container]
      ContainerName=wolf
      Image=ghcr.io/games-on-whales/wolf:stable

      PodmanArgs=--network=host
      PodmanArgs=--security-opt=seccomp:unconfined
      PodmanArgs=--cap-add=ALL
      PodmanArgs=--ipc=host
      PodmanArgs=--privileged
      PodmanArgs=--device=/dev/dri:/dev/dri:rw
      PodmanArgs=--device=/dev/uinput:/dev/uinput:rw
      PodmanArgs=--device=/dev/uhid:/dev/uhid:rw
      PodmanArgs=--device=/dev/snd:/dev/snd:rw
      PodmanArgs=--device=/dev/input:/dev/input:rw
      
      # If needed for mounts (enable if required)
      PodmanArgs=--device=/dev/fuse:/dev/fuse:rw
      
      Environment=TZ=${config.time.timeZone}
      Environment=XDG_RUNTIME_DIR=/tmp/sockets
      Environment=HOST_APPS_STATE_FOLDER=/etc/wolf
      Environment=RUN_SWAY=true  # From docs example, for desktop env
      Environment=LOG_LEVEL=DEBUG  # For more logs
      Environment=WOLF_DRM_DEVICE=/dev/dri/renderD129  # Try alternate render node

      Volume=/home/${config.variables.user.name}/wolf-config:/etc/wolf:rw
      Volume=/tmp/sockets:/tmp/sockets:rw
      Volume=/run/user/1001/podman/podman.sock:/var/run/docker.sock:rw
      
      # Podman socket as Docker compat
      Volume=/run/udev:/run/udev:rw
      Volume=/dev/:/dev/:rw
      
      # Full dev access (adjust if too broad)

      # Optional: Games mount (uncomment if needed)
      # Volume=/mnt/games:/mnt/games:rw

      ShmSize=2gb

      [Service]
      Restart=always
      TimeoutStartSec=900

      [Install]
      WantedBy=default.target
    '';
  };
}
