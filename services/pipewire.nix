{ config, pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    pulse = {
      enable = true;
    };
  };
}

