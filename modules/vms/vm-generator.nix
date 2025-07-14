{ config, lib, pkgs, NixVirt, customIsoImages, ... }:

with lib;

let
  # Imports the vm configurations from variables.nix
  cfg = config.variables.vms;
in
{
  config = mkIf (cfg != {}) {
    # Generates libvirt domain XML definitions for each enabled VM.
    virtualisation.libvirt.connections."qemu:///system".domains =
      mapAttrsToList (name: vm:
        let
          # Sets the installer ISO path if this is the VM's first boot.
          finalIsoPath = if vm.firstBoot && vm.isoName != null
                          then "/var/lib/libvirt/images/${vm.isoName}.iso"
                          else null;

          # Defines the base configuration for a VM template.
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

          # Creates the VM template using NixVirt.
          baseTemplate = NixVirt.lib.domain.templates.pc templateConfig;

          # Removes graphical and audio devices for a headless server setup.
          headlessDevices = builtins.removeAttrs baseTemplate.devices [ "graphics" "video" "sound" "audio" "input" "channel" "redirdev" "hub" ];
          # Adds serial and console devices for terminal access.
          finalDevices = headlessDevices // { serial = [ { type = "pty"; } ]; console = [ { type = "pty"; } ]; };
          # Applies the device configuration to the final template.
          finalConfig = baseTemplate // { devices = finalDevices; };
          # Writes the final configuration to an XML string.
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

    # Opens TCP ports on the host firewall based on the ports defined for each VM.
    networking.firewall.allowedTCPPorts = let
      allVMTCPPorts = flatten (mapAttrsToList (_: vm: vm.firewall.openTCPPorts) (filterAttrs (_: vm: vm.enable) cfg));
    in allVMTCPPorts;

    # Opens UDP ports on the host firewall based on the ports defined for each VM.
    networking.firewall.allowedUDPPorts = let
      allVMUDPPorts = flatten (mapAttrsToList (_: vm: vm.firewall.openUDPPorts) (filterAttrs (_: vm: vm.enable) cfg));
    in allVMUDPPorts;

    # Injects custom iptables rules for advanced NAT and forwarding.
    networking.firewall.extraCommands = let
      externalIface = config.variables.networking.externalInterface;
      bridgeIP = "192.168.122.1";
      # Function to generate port forwarding rules for a given VM.
      genRules = {name, vm}: let ip = vm.ip; in
        if vm.enable && vm.ip != null then
          (lib.concatMapStringsSep "\n" (port: ''
            # DNAT: Forwards incoming traffic from the external interface to the VM.
            iptables -t nat -A PREROUTING -i ${externalIface} -p tcp --dport ${toString port} -j DNAT --to-destination ${ip}:${toString port}
            # DNAT: Forwards traffic originating from the host itself (localhost) to the VM.
            iptables -t nat -A OUTPUT -o lo -p tcp --dport ${toString port} -j DNAT --to-destination ${ip}:${toString port}
            # SNAT: Rewrites the source address to ensure the VM's reply traffic is routed back through the host correctly.
            iptables -t nat -A POSTROUTING -o virbr0 -d ${ip} -p tcp --dport ${toString port} -j SNAT --to-source ${bridgeIP}
          '') vm.firewall.openTCPPorts) +
          (lib.concatMapStringsSep "\n" (port: ''
            iptables -t nat -A PREROUTING -i ${externalIface} -p udp --dport ${toString port} -j DNAT --to-destination ${ip}:${toString port}
            iptables -t nat -A OUTPUT -o lo -p udp --dport ${toString port} -j DNAT --to-destination ${ip}:${toString port}
            iptables -t nat -A POSTROUTING -o virbr0 -d ${ip} -p udp --dport ${toString port} -j SNAT --to-source ${bridgeIP}
          '') vm.firewall.openUDPPorts)
        else "";
    in ''
      # Inserts a rule to allow traffic from the external interface to the virtual bridge.
      iptables -I FORWARD 1 -i ${externalIface} -o virbr0 -j ACCEPT
      # Inserts a rule to allow traffic from the virtual bridge to the external interface.
      iptables -I FORWARD 1 -i virbr0 -o ${externalIface} -j ACCEPT
      # Inserts a rule to allow all traffic that is part of an established connection.
      iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

      # Concatenates and applies the rules generated by the genRules function for all VMs.
      ${lib.concatMapStringsSep "\n" genRules (lib.mapAttrsToList (name: vm: { inherit name vm; }) cfg)}
    '';

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
