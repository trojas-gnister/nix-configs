{ config, lib, pkgs, NixVirt, customIsoImages ? {}, ... }:

with lib;

let
  cfg = config.virtualisation.nixvirt.vms;
in
{
  options.virtualisation.nixvirt.vms = mkOption {
    type = types.attrsOf (types.submodule ({ name, ... }: {
      options = {
        enable = mkEnableOption "NixOS VM named ${name}";
        diskPath = mkOption {
          type = types.str;
          description = "Path to the qcow2 disk image for the VM.";
        };
        memorySize = mkOption {
          type = types.int;
          default = 4;
          description = "RAM size in GiB.";
        };
        uuid = mkOption {
          type = types.str;
          description = "Unique UUID for the VM.";
        };
        isoName = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The name of the ISO build (e.g., 'torrent-vm') to use for installation. Must match a key in customIsoImages.";
        };
        firstBoot = mkOption {
          type = types.bool;
          default = false;
          description = "If true, attach the installer ISO for initial installation.";
        };
      };
    }));
    default = {};
    description = "Declarative definition of NixOS virtual machines.";
  };

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
          isoDerivation = customIsoImages.${vm.isoName} or (throw "ISO configuration '${vm.isoName}' for VM '${vmName}' is not defined. Check your flake's specialArgs.");
          srcPathGlob = "${isoDerivation}/iso/*.iso";
          destPath = "/var/lib/libvirt/images/${vm.isoName}.iso";
        in ''
          echo "Processing ISO for VM: ${vmName}"
          iso_files=(${srcPathGlob})
          if [ ''${#iso_files[@]} -ne 1 ]; then
            echo "ERROR: Expected 1 ISO file in ${isoDerivation}/iso for '${vm.isoName}', but found ''${#iso_files[@]}." >&2
            exit 1
          fi
          if [ ! -f "${destPath}" ] || ! cmp -s "''${iso_files[0]}" "${destPath}"; then
            echo "Copying ''${iso_files[0]} to ${destPath}"
            cp "''${iso_files[0]}" "${destPath}"
            chmod 644 "${destPath}"
          else
            echo "ISO for ${vmName} is already up-to-date."
          fi
        ''
      ) (lib.filterAttrs (n: v: v.enable && v.firstBoot && v.isoName != null) cfg);
    in {
      deps = [ "libvirtd" ];
      text = ''
        echo "Setting up VM ISOs in /var/lib/libvirt/images/..."
        mkdir -p /var/lib/libvirt/images
        ${lib.concatStringsSep "\n" copyCommands}
        echo "Finished setting up VM ISOs."
      '';
    };
  };
}

