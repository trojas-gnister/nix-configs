{ config, lib, pkgs, NixVirt, customIsoImage, ... }:

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
        isoPath = mkOption {
          type = types.str;
          default = "/var/lib/libvirt/images/nixos-vm-installer.iso";
          description = "Path to the installer ISO for the VM.";
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
          templateConfig = {
            inherit name;
            uuid = vm.uuid;
            uefi = true;
            memory = { count = vm.memorySize; unit = "GiB"; };
            storage_vol = vm.diskPath;
            bridge_name = "default";
            virtio_net = true;
          } // (lib.optionalAttrs vm.firstBoot {
            install_vol = vm.isoPath;
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

    system.activationScripts.copyVmInstallerIso = ''
      echo "Copying VM installer ISO to /var/lib/libvirt/images..."
      shopt -s nullglob
      iso_files=("${customIsoImage}/iso/"*.iso)
      if [ ''${#iso_files[@]} -ne 1 ]; then
        echo "ERROR: Expected to find exactly one .iso file in ${customIsoImage}/iso, but found ''${#iso_files[@]}." >&2
        ls -lR "${customIsoImage}" >&2
        exit 1
      fi
      src_iso_path="''${iso_files[0]}"
      mkdir -p /var/lib/libvirt/images
      cp "$src_iso_path" /var/lib/libvirt/images/nixos-vm-installer.iso
      chmod 644 /var/lib/libvirt/images/nixos-vm-installer.iso
      echo "Successfully copied $src_iso_path"
    '';
  };
}
