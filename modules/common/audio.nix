{ config, lib, pkgs, ... }:

{
  security.rtkit.enable = true;
  hardware.alsa.enablePersistence = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };
}
