# modules/common/ssh.nix
{ config, lib, pkgs, ... }:

{
  services.openssh.enable = true;
}
