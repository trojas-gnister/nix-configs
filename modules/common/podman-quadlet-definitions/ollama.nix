{ pkgs, config, lib, ... }:
{
  "containers/systemd/ollama.container" = {
    text = ''
      [Unit]
      Description=Ollama Container
      Wants=network-online.target
      After=network-online.target

      [Container]
      ContainerName=ollama
      Image=docker.io/ollama/ollama:rocm

      PodmanArgs=--replace
      PodmanArgs=--device=/dev/kfd
      PodmanArgs=--device=/dev/dri
      PodmanArgs=--security-opt=seccomp:unconfined

      Environment=HSA_OVERRIDE_GFX_VERSION=11.0.0
      Environment=OLLAMA_DEBUG=1
      Environment=OLLAMA_HOST=0.0.0.0:11434
      PublishPort=127.0.0.1:11434:11434
      Volume=ollama-data:/root/.ollama

      [Service]
      Restart=on-failure
      TimeoutStartSec=300

      [Install]
      WantedBy=default.target
    '';
  };
}
