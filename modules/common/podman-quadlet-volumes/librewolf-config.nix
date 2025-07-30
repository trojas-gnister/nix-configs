{ pkgs, config, lib, ... }:
{
  "containers/systemd/librewolf-config.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}

