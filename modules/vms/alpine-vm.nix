{ config, pkgs, lib, NixVirt, ... }:

let
  vmName = "alpine-vm";
  alpineVars = config.variables.vms.alpine;

  baseTemplate = NixVirt.lib.domain.templates.pc {
    name = vmName;
    uuid = "599db290-80ad-48f6-a8c3-41e52d5bb2c9";
    memory = { count = 2; unit = "GiB"; };
    storage_vol = alpineVars.diskPath;
    install_vol = alpineVars.isoPath;
    bridge_name = null;
    virtio_net = true;
  };

  headlessDevices = builtins.removeAttrs baseTemplate.devices [
    "graphics"
    "video"
    "sound"
    "audio"
    "input"
    "channel"
    "redirdev"
    "hub"
  ];

  finalDevices = headlessDevices // {
    serial = [ { type = "pty"; } ];
    console = [ { type = "pty"; } ];
  };

  finalConfig = baseTemplate // { devices = finalDevices; };

  domainXML = NixVirt.lib.domain.writeXML finalConfig;

in
{
  virtualisation.libvirt.connections."qemu:///system".domains = [{
    definition = domainXML;
    active = false;
  }];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "connect-alpine" ''
      #!/bin/sh
      virsh --connect qemu:///system console ${vmName}
    '')
  ];
}
