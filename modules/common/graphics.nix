{ config, lib, pkgs, ... }:

{
  hardware.graphics.enable = true;
  environment.pathsToLink = [ "/libexec" ];
}
