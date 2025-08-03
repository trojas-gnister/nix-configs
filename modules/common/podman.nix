{ config, lib, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Add the systemd user generator for Quadlet
  environment.etc."systemd/user-generators/podman-user-generator" = {
    source = "${pkgs.podman}/lib/systemd/user-generators/podman-user-generator";
  };

  # Enable uinput for virtual input devices (gamepads)
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input"
  '';
  users.users.${config.variables.user.name}.extraGroups = [ "input" ];

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
