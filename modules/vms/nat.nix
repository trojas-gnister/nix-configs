# /etc/nixos/modules/vms/nat.nix (Simplified for socat)
{ config, lib, ... }: {
  boot.kernelModules = [ "br_netfilter" ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
  };

  networking.firewall.extraCommands = ''
    # Allow forwarding for any traffic originating from the host itself (like from socat) to the VM network.
    iptables -A FORWARD -i lo -o virbr0 -j ACCEPT
    iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  '';

  networking.firewall.extraStopCommands = ''
    iptables -F FORWARD
  '';
}
