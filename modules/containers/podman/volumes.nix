# modules/containers/podman/volumes.nix
{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = {
    systemd.user.services = {
      # Create volumes
      podman-create-volumes = {
        Unit = {
          Description = "Create Podman volumes for containers";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.writeShellScript "create-podman-volumes" ''
            ${pkgs.podman}/bin/podman volume exists ollama-data || ${pkgs.podman}/bin/podman volume create ollama-data
            ${pkgs.podman}/bin/podman volume exists steamos-data || ${pkgs.podman}/bin/podman volume create steamos-data
            ${pkgs.podman}/bin/podman volume exists open-webui-data || ${pkgs.podman}/bin/podman volume create open-webui-data
          ''}";
        };
      };
    };
  };
}
