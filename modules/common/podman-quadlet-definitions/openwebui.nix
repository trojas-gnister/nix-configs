{ pkgs, config, lib, ... }:
{
  "containers/systemd/openwebui.container" = {
    text = ''
      [Unit]
      Description=Open WebUI Container
      Wants=network-online.target ollama.service
      After=network-online.target ollama.service

      [Container]
      ContainerName=open-webui
      Image=ghcr.io/open-webui/open-webui:main
      PodmanArgs=--replace
      Network=host
      Environment=OLLAMA_BASE_URL=http://127.0.0.1:11434
      Volume=open-webui-data:/app/backend/data

      [Service]
      Restart=on-failure

      [Install]
      WantedBy=default.target
    '';
  };
}
