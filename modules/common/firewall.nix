{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = config.variables.firewall.openTCPPorts;
    allowedUDPPorts = config.variables.firewall.openUDPPorts;
    allowedTCPPortRanges = config.variables.firewall.openTCPPortRanges;
    allowedUDPPortRanges = config.variables.firewall.openUDPPortRanges;
    trustedInterfaces = config.variables.firewall.trustedInterfaces;
  };
}
