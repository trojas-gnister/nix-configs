{ pkgs, config, lib, ... }:
{
  "containers/systemd/gluetun.container" = {
    text = ''
      [Unit]
      Description=Gluetun VPN Container
      Wants=network-online.target
      After=network-online.target

      [Container]
      ContainerName=gluetun-vpn
      Image=qmcgaw/gluetun:latest
      PodmanArgs=--replace
      Volume=gluetun-config:/gluetun
      Environment=VPN_SERVICE_PROVIDER=mullvad
      Environment=VPN_TYPE=wireguard
      Environment=WIREGUARD_PRIVATE_KEY=2FUODTeX8hxJzgw1QdWRuSJrcdunxFCj2yTqX6Qtm0M=
      Environment=WIREGUARD_ADDRESSES=10.64.0.1
      Environment=TZ=${config.time.timeZone}
      ShmSize=1gb

      [Install]
      WantedBy=default.target
    '';
  };
}

