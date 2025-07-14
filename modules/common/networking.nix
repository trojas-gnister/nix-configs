{ config, lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  environment.variables.GTK_THEME = "Adwaita:dark";

  # Enable NAT with forwarding from external interface to internal interfaces
  networking.nat = {
    enable = true;
    enableIPv6 = false;
    externalInterface = config.variables.networking.externalInterface;  # e.g., "wlo1"
    internalInterfaces = config.variables.networking.internalInterfaces;  # e.g., [ "virbr0" ]
  };

  # Enable IP forwarding and disable reverse path filtering
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.${config.variables.networking.externalInterface}.rp_filter" = 0;
    "net.ipv4.conf.virbr0.rp_filter" = 0;
  };

  # Define rt_tables for policy routing
  environment.etc."iproute2/rt_tables".text = lib.mkDefault ''
    200 localhairpin
  '';

  # Force sysctls and policy routing post-boot (with full paths for activation environment)
  system.activationScripts.forceNetworking = ''
    ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.${config.variables.networking.externalInterface}.rp_filter=0 || true
    ${pkgs.procps}/bin/sysctl -w net.ipv4.conf.virbr0.rp_filter=0 || true
    HOST_IP=$(${pkgs.iproute2}/bin/ip addr show ${config.variables.networking.externalInterface} | ${pkgs.gawk}/bin/awk '/inet / {print $2}' | ${pkgs.coreutils}/bin/cut -d/ -f1)
    ${pkgs.iproute2}/bin/ip rule add from $HOST_IP table localhairpin || true
    ${pkgs.iproute2}/bin/ip route add 192.168.122.0/24 via 192.168.122.1 dev virbr0 table localhairpin || true
    ${pkgs.iproute2}/bin/ip route flush cache || true
  '';
}
