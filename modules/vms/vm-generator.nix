{ config, lib, pkgs, NixVirt, customIsoImages ? {}, ... }:

with lib;

let
  cfg = config.variables.vms;
in
{
  config = mkIf (cfg != {}) {
    virtualisation.libvirt.connections."qemu:///system".domains =
      mapAttrsToList (name: vm:
        let
          finalIsoPath = if vm.firstBoot && vm.isoName != null
                         then "/var/lib/libvirt/images/${vm.isoName}.iso"
                         else null;

          templateConfig = {
            inherit name;
            uuid = vm.uuid;
            uefi = true;
            memory = { count = vm.memorySize; unit = "GiB"; };
            storage_vol = vm.diskPath;
            bridge_name = "virbr0";
            virtio_net = true;
          } // (lib.optionalAttrs (finalIsoPath != null) {
            install_vol = finalIsoPath;
          });

          baseTemplate = NixVirt.lib.domain.templates.pc templateConfig;
          headlessDevices = builtins.removeAttrs baseTemplate.devices [ "graphics" "video" "sound" "audio" "input" "channel" "redirdev" "hub" ];
          finalDevices = headlessDevices // { serial = [ { type = "pty"; } ]; console = [ { type = "pty"; } ]; };
          finalConfig = baseTemplate // { devices = finalDevices; };
          domainXML = NixVirt.lib.domain.writeXML finalConfig;
        in
        {
          definition = domainXML;
          active = false;
        }
      ) (filterAttrs (n: v: v.enable) cfg);

    environment.systemPackages =
      mapAttrsToList (name: vm:
        pkgs.writeShellScriptBin "connect-${name}" ''
          #!/bin/sh
          virsh --connect qemu:///system console ${name}
        ''
      ) (filterAttrs (n: v: v.enable) cfg);

    system.activationScripts.copyVmIsos = let
      copyCommands = lib.mapAttrsToList (vmName: vm:
        let
          isoBuildDir = customIsoImages.${vm.isoName} or (throw "ISO configuration '${vm.isoName}' for VM '${vmName}' is not defined. Check your flake's specialArgs.");
          destPath = "/var/lib/libvirt/images/${vm.isoName}.iso";
        in ''
          echo "Processing ISO for VM: ${vmName}"
          shopt -s nullglob
          iso_files=("${isoBuildDir}/iso/"*.iso)
          if [ ''${#iso_files[@]} -ne 1 ]; then
            echo "ERROR: Expected to find exactly one .iso file in ${isoBuildDir}/iso, but found ''${#iso_files[@]}." >&2
            exit 1
          fi
          
          src_iso_path="''${iso_files[0]}"

          if [ ! -f "${destPath}" ] || ! cmp -s "$src_iso_path" "${destPath}"; then
            echo "Copying $src_iso_path to ${destPath}"
            cp "$src_iso_path" "${destPath}"
            chmod 644 "${destPath}"
          else
            echo "ISO for ${vmName} is already up-to-date."
          fi
        ''
      ) (lib.filterAttrs (n: v: v.enable && v.firstBoot && v.isoName != null) cfg);
    in {
      text = ''
        echo "Setting up VM ISOs in /var/lib/libvirt/images/..."
        mkdir -p /var/lib/libvirt/images
        ${lib.concatStringsSep "\n" copyCommands}
        echo "Finished setting up VM ISOs."
      '';
    };
  };
}
