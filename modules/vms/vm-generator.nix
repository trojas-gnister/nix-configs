# Updated ./modules/vms/vm-generator.nix
{ config, lib, pkgs, NixVirt, customIsoImages, ... }:
with lib;
let
  cfg = config.variables.vms;
in
{
  config = mkIf (cfg != {}) {
    # Generates libvirt domain XML definitions for each enabled VM.
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
            vcpu = { count = vm.vcpuCount; placement = "static"; };
            storage_vol = vm.diskPath;
            bridge_name = "virbr0";
            virtio_net = true;
          } // (lib.optionalAttrs (finalIsoPath != null) {
            install_vol = finalIsoPath;
          });
          baseTemplate = NixVirt.lib.domain.templates.pc templateConfig;
          headlessDevices = builtins.removeAttrs baseTemplate.devices [ "graphics" "video" "sound" "audio" "input" "channel" "redirdev" "hub" ];
          finalDevices = headlessDevices // { video = [ { model.type = "none"; } ]; serial = [ { type = "pty"; } ]; console = [ { type = "pty"; } ]; };
          finalConfig = baseTemplate // { devices = finalDevices; };
          domainXML = NixVirt.lib.domain.writeXML finalConfig;
        in
        {
          definition = domainXML;
          active = false;
        }
      ) (filterAttrs (n: v: v.enable) cfg);
    # Creates a helper script in /run/current-system/sw/bin for each VM
    # to provide easy console access via `virsh`.
    environment.systemPackages =
      mapAttrsToList (name: vm:
        pkgs.writeShellScriptBin "connect-${name}" ''
          #!/bin/sh
          virsh --connect qemu:///system console ${name}
        ''
      ) (filterAttrs (n: v: v.enable) cfg);
    # This script runs during system activation to prepare VM storage.
    system.activationScripts.setupVms =
      let
        vmSetupCommands = lib.mapAttrsToList (name: vm: ''
          # Creates a qcow2 disk image for the VM if it doesn't already exist.
          if [ ! -f "${vm.diskPath}" ]; then
            echo "Creating new qcow2 disk for ${name} at ${vm.diskPath}"
            ${pkgs.qemu}/bin/qemu-img create -f qcow2 "${vm.diskPath}" ${toString vm.diskSize}G
          fi
          # Copies the specified installer ISO to the libvirt images directory if needed.
          ${lib.optionalString (vm.enable && vm.firstBoot && vm.isoName != null) ''
            echo "Processing ISO for VM: ${name}"
            src_iso_dir="${customIsoImages.${vm.isoName}}"
            destPath="/var/lib/libvirt/images/${vm.isoName}.iso"
            shopt -s nullglob
            iso_files=("$src_iso_dir"/iso/*.iso)
            if [ ''${#iso_files[@]} -ne 1 ]; then
              echo "ERROR: Expected to find exactly one .iso file in $src_iso_dir/iso, but found ''${#iso_files[@]}." >&2
              exit 1
            fi
            src_iso_path="''${iso_files[0]}"
         
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
