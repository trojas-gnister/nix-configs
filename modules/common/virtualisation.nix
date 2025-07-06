{ config, lib, pkgs, NixVirt, ... }:

let
  dhcpHosts = lib.mapAttrsToList (name: vm: {
    inherit name;
    mac = vm.mac;
    ip = vm.ip;
  }) (lib.filterAttrs (name: vm: vm.enable && vm.mac != null && vm.ip != null) config.variables.vms);

  networkXML = NixVirt.lib.network.writeXML {
    name = "default";
    uuid = "0af7f5c1-ab7f-4bd2-9512-ad18feb93254";
    forward.mode = "nat";
    bridge.name = "virbr0";
    ip = {
      address = "192.168.122.1";
      netmask = "255.255.255.0";
      dhcp = {
        range = { start = "192.168.122.100"; end = "192.168.122.254"; };
        hosts = dhcpHosts;
      };
    };
  };
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
  };

  virtualisation.libvirt = {
    enable = true;
    connections."qemu:///system".networks = [{
      definition = networkXML;
      active = true;
    }];
  };

  environment.systemPackages = with pkgs; [
    virt-manager
  ];
}
