{ pkgs, config, lib, ... }:
{
  "containers/systemd/obsidian-config.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
