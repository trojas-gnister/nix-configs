# modules/containers/podman/ollama.nix
{ config, lib, pkgs, ... }:

{
  home-manager.users.${config.variables.user.name} = {
    systemd.user.services = {
      podman-ollama = {
        Unit = {
          Description = "Ollama Container";
          Requires = [ "podman-create-volumes.service" ];
          After = [ "podman-create-volumes.service" ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
        Service = {
          Type = "forking";
          RemainAfterExit = "yes";
          ExecStartPre = "${pkgs.writeShellScript "clean-ollama-container" ''
            # Force remove any existing container with stronger cleanup
            ${pkgs.podman}/bin/podman rm -f ollama 2>/dev/null || true
            # Clean any leftovers that might be causing issues
            ${pkgs.podman}/bin/podman system prune -f 2>/dev/null || true
          ''}";
          ExecStart = "${pkgs.writeShellScript "start-ollama-container" ''
            ${pkgs.podman}/bin/podman run --name ollama \
              --device=/dev/kfd \
              --device=/dev/dri \
              --group-add=keep-groups \
              --security-opt=label=type:container_runtime_t \
              -e HSA_OVERRIDE_GFX_VERSION=11.0.0 \
              -e OLLAMA_DEBUG=1 \
              -e OLLAMA_HOST=http://0.0.0.0:11434 \
              -p 11434:11434 \
              -p 3000:3000 \
              -v ollama-data:/root/.ollama \
              -d ollama/ollama:rocm
          ''}";
          ExecStop = "${pkgs.writeShellScript "stop-ollama-container" ''
            ${pkgs.podman}/bin/podman stop -t 10 ollama || true
          ''}";
        };
      };
    };
  };
}
