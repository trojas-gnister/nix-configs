{ pkgs, config, lib, ... }:
{
  "containers/systemd/ollama-data.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
