# modules/common/firewall.nix
{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = config.variables.firewall.openTCPPorts;
    allowedUDPPorts = config.variables.firewall.openUDPPorts;
    allowedUDPPortRanges = config.variables.firewall.openUDPPortRanges;
  };
}
