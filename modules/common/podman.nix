# modules/common/podman.nix
{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Add the systemd user generator for Quadlet
  environment.etc."systemd/user-generators/podman-user-generator" = {
    source = "${pkgs.podman}/lib/systemd/user-generators/podman-user-generator";
  };
  
  # Enable user lingering for the primary user so services start on boot
  users.users.${config.variables.user.name}.linger = true;
  
  # Make sure network-online.target is properly handled for user services
  systemd.user.services.podman-user-wait-network-online = {
    description = "Wait for system level network-online.target";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };
}
