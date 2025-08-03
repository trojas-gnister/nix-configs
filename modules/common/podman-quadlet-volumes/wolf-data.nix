{ pkgs, config, lib, ... }:
{
  "containers/systemd/wolf-data.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
