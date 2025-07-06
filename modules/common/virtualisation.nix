{ config, lib, pkgs, NixVirt, ... }:

let
  networkXML = NixVirt.lib.network.writeXML (NixVirt.lib.network.templates.bridge {
    uuid = "0af7f5c1-ab7f-4bd2-9512-ad18feb93254";
    subnet_byte = 122;
    name = "default";
    bridge_name = "virbr0";
  });
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
