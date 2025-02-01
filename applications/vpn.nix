{ config, pkgs, ... }:
{
  # MAY NOT BE NEEDED
  environment.systemPackages = [ pkgs.mullvad-vpn ];
  mullvad-vpn.enable = true;                                                                                                                  
    mullvad-vpn.package = pkgs.mullvad-vpn;
}

