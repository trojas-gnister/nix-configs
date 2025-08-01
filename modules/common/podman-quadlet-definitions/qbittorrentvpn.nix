{ pkgs, config, lib, ... }:

let
  homeDir = "/home/${config.variables.user.name}";
in
{
  "containers/systemd/user/qbittorrentvpn.container" = {
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
      Environment=LAN_NETWORK=192.168.122.0/24,192.168.1.0/24
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
