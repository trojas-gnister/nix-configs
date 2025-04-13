# modules/containers/podman/steamos.nix
{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = {
    systemd.user.services = {
      podman-steamos = {
        Unit = {
          Description = "SteamOS Container";
          Requires = [ "podman-create-volumes.service" ];
          After = [ "podman-create-volumes.service" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "forking";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.writeShellScript "start-steamos-container" ''
            ${pkgs.podman}/bin/podman container exists steamos && ${pkgs.podman}/bin/podman rm -f steamos || true
            ${pkgs.podman}/bin/podman run --name steamos \
              --cap-add=NET_ADMIN \
              --cap-add=SYS_ADMIN \
              --security-opt=seccomp=unconfined \
              --security-opt=apparmor=unconfined \
              --device=/dev/kfd \
              --device=/dev/dri \
              --group-add=keep-groups \
              --memory=16g \
              --memory-reservation=14g \
              --cap-add=MKNOD \
              --device=/dev/uinput:/dev/uinput \
              -e PUID=1000 \
              -e PGID=1000 \
              -e TZ=Etc/UTC \
              -e DRINODE=/dev/dri/renderD128 \
              -p 5000:3000 \
              -p 27031-27036:27031-27036/udp \
              -p 27031-27036:27031-27036 \
              -p 47984-47990:47984-47990 \
              -p 48010:48010 \
              -p 47998-48000:47998-48000/udp \
              -p 27031-27036:27031-27036/udp \
              -p 27031-27036:27031-27036 \
              -v steamos-data:/config \
              -v /dev/input:/dev/input \
              -v /run/udev/data:/run/udev/data \
              --shm-size=1gb \
              -d linuxserver/steamos:latest
          ''}";
          ExecStop = "${pkgs.writeShellScript "stop-steamos-container" ''
            ${pkgs.podman}/bin/podman stop -t 10 steamos || true
            ${pkgs.podman}/bin/podman rm -f steamos || true
          ''}";
        };
      };
    };
  };
}
