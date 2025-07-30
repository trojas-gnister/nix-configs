{ pkgs, config, lib, ... }:
{
  "containers/systemd/user/swag.container" = {
    text = ''
      [Unit]
      Description=SWAG - Secure Web Application Gateway
      After=network-online.target

      [Container]
      Image=lscr.io/linuxserver/swag:latest
      ContainerName=swag
      PodmanArgs=--cap-add=NET_ADMIN
      
      Volume=swag-config:/config
      
      Environment=PUID=1000
      Environment=PGID=1000
      Environment=TZ=${config.time.timeZone}
      Environment=URL=browserspace.local
      Environment=VALIDATION=http
      Environment=STAGING=false
      Environment=ONLY_SUBDOMAINS=false
      
      PublishPort=80:80
      PublishPort=443:443
      PublishPort=443:443/udp

      [Service]
      Restart=unless-stopped

      [Install]
      WantedBy=default.target
    '';
  };
}
