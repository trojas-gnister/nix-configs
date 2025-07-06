{ config, lib, ... }:

let
  vms = config.variables.vms;

  vmsToForward = lib.filterAttrs (name: vm: vm.enable && vm.ip != null && vm.forwardedPorts != []) vms;

  forwardingRules = lib.concatMap (vmName:
    let
      vm = vms.${vmName};
    in
      lib.map (port:
        let
          finalDestPort = if port.destinationPort == null
                          then port.sourcePort
                          else port.destinationPort;
        in
        {
          inherit (port) proto sourcePort;
          destination = "${vm.ip}:${toString finalDestPort}";
        }
      ) vm.forwardedPorts
  ) (lib.attrNames vmsToForward);
in
{
  networking.nat = lib.mkIf (forwardingRules != []) {
    enable = true;
    externalInterface = config.variables.networking.externalInterface;
    forwardPorts = forwardingRules;
  };
}
