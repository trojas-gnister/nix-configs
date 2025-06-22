# modules/common/podman-quadlet-definitions/gluetun.nix
{ pkgs, config, lib, ... }:

let
  homeDir = "/home/iskry";
in
{
  "containers/systemd/gluetun.container" = {
    text = ''
      [Unit]
      Description=Gluetun (Mullvad) VPN Container
      After=network-online.target

      [Container]
      Image=qmcgaw/gluetun:latest
      ContainerName=gluetun
      PodmanArgs=--cap-add=NET_ADMIN --device=/dev/net/tun:/dev/net/tun

      # Persist Gluetun’s state/config
      Volume=${homeDir}/gluetun:/gluetun

      # Expose your Mullvad-assigned port for torrent traffic
      PublishPort=51820:51820    # ↳ torrent port forwarding
      
      # Expose qBittorrent web UI
      PublishPort=8080:8080                # ↳ qBittorrent WebUI
      
      # Expose qBittorrent peer port
      PublishPort=6881:6881                # ↳ torrent peer connections
      
      
      # Expose Prowlarr web UI
      PublishPort=9696:9696                # ↳ Prowlarr WebUI

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}

