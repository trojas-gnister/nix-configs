{ pkgs, config, lib, ... }:

let
  homeDir = config.home.homeDirectory;
in
{
  xdg.configFile."containers/systemd/qbittorrentvpn.container" = {
    text = ''
      [Unit]
      Description=qBittorrentVPN Container
      After=network-online.target

      [Container]
      Image=docker.io/dyonr/qbittorrentvpn:latest
      ContainerName=qbittorrentvpn
      PodmanArgs=--privileged
      Volume=${homeDir}/qbittorrent/config:/config
      Volume=${homeDir}/qbittorrent/downloads:/downloads
      Environment=VPN_ENABLED=yes
      Environment=VPN_TYPE=wireguard
      Environment=LAN_NETWORK=192.168.1.0/24
      Environment=PUID=1000
      Environment=PGID=1000
      PublishPort=8000:8080

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}
