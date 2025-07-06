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

    system.activationScripts.setupVms =
      let
        vmSetupCommands = lib.mapAttrsToList (name: vm: ''
          if [ ! -f "${vm.diskPath}" ]; then
            echo "Creating new qcow2 disk for ${name} at ${vm.diskPath}"
            ${pkgs.qemu}/bin/qemu-img create -f qcow2 "${vm.diskPath}" ${toString vm.diskSize}G
          fi

          ${lib.optionalString (vm.enable && vm.firstBoot && vm.isoName != null) ''
            echo "Processing ISO for VM: ${name}"
            # Use the --json flag and parse with jq for a robust solution
            src_iso_path=$(${pkgs.nix}/bin/nix path-info --json -S ${customIsoImages.${vm.isoName}} | ${pkgs.jq}/bin/jq -r '.[0].path')
            destPath="/var/lib/libvirt/images/${vm.isoName}.iso"
            
            if [ ! -f "$destPath" ] || ! ${pkgs.diffutils}/bin/cmp -s "$src_iso_path" "$destPath"; then
              echo "Copying $src_iso_path to $destPath"
              cp "$src_iso_path" "$destPath"
              chmod 644 "$destPath"
            else
              echo "ISO for ${name} is already up-to-date."
            fi
          ''}
        '') (lib.filterAttrs (n: v: v.enable) cfg);
      in
      {
        text = ''
          echo "Setting up VM disks and ISOs in /var/lib/libvirt/images/..."
          mkdir -p /var/lib/libvirt/images
          ${lib.concatStringsSep "\n" vmSetupCommands}
          echo "Finished setting up VM disks and ISOs."
        '';
      };
  };
}
