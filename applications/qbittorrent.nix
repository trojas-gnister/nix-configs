{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.qbittorrent ];
}

