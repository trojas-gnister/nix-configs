{ config, lib, ... }:

let
  vms = config.variables.vms;

  vmsToForward = lib.filterAttrs (name: vm: vm.enable && vm.ip != null && vm.forwardedPorts != []) vms;

  forwardingRules = lib.concatMap (vmName:
    let
      vm = vms.${vmName};
    in
      lib.map (port: {
        proto = port.proto;
        sourcePort = port.sourcePort;
        destination = "${vm.ip}:${toString (port.destinationPort or port.sourcePort)}";
      }) vm.forwardedPorts
  ) (lib.attrNames vmsToForward);
in
{
  networking.nat = lib.mkIf (forwardingRules != []) {
    enable = true;
    externalInterface = config.variables.networking.externalInterface;
    forwardPorts = forwardingRules;
  };
}
