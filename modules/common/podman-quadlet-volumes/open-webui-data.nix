{ pkgs, config, lib, ... }:
{
  "containers/systemd/open-webui-data.volume" = {
    text = ''
      [Volume]
      Driver=local
    '';
  };
}
