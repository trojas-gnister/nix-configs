{ pkgs, config, lib, ... }:
{
  "containers/systemd/steamos-data.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
