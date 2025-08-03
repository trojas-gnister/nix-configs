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
  config = lib.mkMerge [
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
    (lib.mkIf config.variables.vfio.enable {
      boot = {
        kernelModules = [ "vfio_pci" ];
        blacklistedKernelModules = config.variables.vfio.blacklistedDrivers;
        extraModprobeConfig = ''
          options vfio-pci ids=${lib.strings.concatStringsSep "," config.variables.vfio.pciIds}
          ${lib.concatMapStringsSep "\n" (driver: "softdep ${driver} pre: vfio vfio_pci") config.variables.vfio.blacklistedDrivers}
        '';
      };
    })
    (lib.mkIf (config.variables.vfio.enable && config.variables.vfio.isolatedCores != "") {
      boot.kernelParams = [ "isolcpus=${config.variables.vfio.isolatedCores}" ];
    })
  ];
}
