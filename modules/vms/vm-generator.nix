# Updated ./modules/vms/vm-generator.nix

{ config, lib, pkgs, NixVirt, customIsoImages, ... }:
with lib;
let
  cfg = config.variables.vms;
  hexToInt = hex: let
    hexMap = {
      "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
      "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
      "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
    };
    lowerHex = lib.strings.toLower hex;
  in builtins.foldl' (acc: c: acc * 16 + (hexMap.${c})) 0 (lib.strings.stringToCharacters lowerHex);
  parsePCI = addr: let
    parts = strings.splitString ":" addr;
    slot_func = strings.splitString "." (elemAt parts 2);
  in {
    domain = hexToInt (elemAt parts 0);
    bus = hexToInt (elemAt parts 1);
    slot = hexToInt (elemAt slot_func 0);
    function = hexToInt (elemAt slot_func 1);
  };
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
          passthroughDevices = headlessDevices // { video = [ { model.type = "none"; } ]; };
          devicesWithHostdev = if (vm.pciDevices != []) then passthroughDevices // {
            hostdev = map (addr: {
              mode = "subsystem";
              type = "pci";
              managed = true;
              source = { address = parsePCI addr; };
            }) vm.pciDevices;
          } else passthroughDevices;
          finalDevices = devicesWithHostdev // { serial = [ { type = "pty"; } ]; console = [ { type = "pty"; } ]; };
          cputuneConfig = if (vm.cpuPinning != "") then {
            cputune = {
              vcpupin = genList (i: { vcpu = i; cpuset = vm.cpuPinning; }) vm.vcpuCount;
            };
          } else {};
          finalConfig = baseTemplate // cputuneConfig // { devices = finalDevices; };
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
