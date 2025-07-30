{ pkgs, config, lib, ... }:
{
  "containers/systemd/swag-config.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
