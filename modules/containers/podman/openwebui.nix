# modules/containers/podman/openwebui.nix
{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = {
    systemd.user.services = {
      podman-openwebui = {
        Unit = {
          Description = "Open WebUI Container";
          Requires = [ "podman-ollama.service" ];
          After = [ "podman-ollama.service" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "forking";
          RemainAfterExit = "yes";
          ExecStartPre = "${pkgs.writeShellScript "clean-openwebui-container" ''
            # Force remove any existing container with stronger cleanup
            ${pkgs.podman}/bin/podman rm -f open-webui 2>/dev/null || true
          ''}";
          ExecStart = "${pkgs.writeShellScript "start-openwebui-container" ''
            ${pkgs.podman}/bin/podman run --name open-webui \
              --network=host \
              -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
              -v open-webui-data:/app/backend/data \
              -d ghcr.io/open-webui/open-webui:main
          ''}";
          ExecStop = "${pkgs.writeShellScript "stop-openwebui-container" ''
            ${pkgs.podman}/bin/podman stop -t 10 open-webui || true
            ${pkgs.podman}/bin/podman rm -f open-webui || true
          ''}";
        };
      };
    };
  };
}
