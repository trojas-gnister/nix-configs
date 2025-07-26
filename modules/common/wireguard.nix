# modules/common/wireguard.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.variables.wireguard or {};
in
{
  config = lib.mkIf (cfg.clientConfigPath != "") {
    # No need for explicit enable; defining interfaces enables wg-quick

    # Open UDP port (adjust if different in conf)
    networking.firewall.allowedUDPPorts = [ 51820 ];

    # Define interface using the full .conf file
    networking.wg-quick.interfaces = {
      wg0 = {
        configFile = cfg.clientConfigPath;
        autostart = true;
      };
    };

    # Ensure permissions during activation
    system.activationScripts.wireguardPermissions = lib.strings.optionalString true ''
      if [ -f "${cfg.clientConfigPath}" ]; then
        chmod 600 "${cfg.clientConfigPath}"
        chown root:root "${cfg.clientConfigPath}" || true
      fi
    '';
  };
}
