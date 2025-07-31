{ pkgs, config, lib, ... }:
{
  "containers/systemd/steam-headless-config.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}