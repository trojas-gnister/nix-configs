# /etc/nixos/modules/vms/proxy.nix
{ config, lib, pkgs, ... }:

with lib;

let
  vmsCfg = config.variables.vms;
in
{
  # Create a systemd service for each port forward we need.
  systemd.services = mkMerge (
    flatten (
      mapAttrsToList (vmName: vm:
        if vm.enable && vm.ip != null then
          # Create services for TCP ports
          (map (port:
            let
              serviceName = "socat-proxy-${vmName}-tcp-${toString port}";
            in {
              "${serviceName}" = {
                description = "socat proxy for ${vmName} TCP port ${toString port}";
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = ''
                    ${pkgs.socat}/bin/socat TCP4-LISTEN:${toString port},fork,reuseaddr TCP4:${vm.ip}:${toString port}
                  '';
                  Restart = "always";
                  RestartSec = "5s";
                };
              };
            }
          ) vm.firewall.openTCPPorts)
          # You could add UDP proxies here too with UDP4-LISTEN if needed
        else
          []
      ) vmsCfg
    )
  );
}
