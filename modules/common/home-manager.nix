# modules/common/home-manager.nix
{ config, lib, pkgs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${config.variables.user.name} = {
      home.stateVersion = "24.11";
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    liberation_ttf
    mplus-outline-fonts.githubRelease
    noto-fonts
    noto-fonts-emoji
    proggyfonts
  ];
      services.podman = {
        enable = true;
      };

      xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';

      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
        "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
        "org/gnome/shell" = { disable-user-extensions = false; };
      };

      # Quadlet container definitions
      xdg.configFile."containers/systemd/dev-env.container" = {
        text = ''
          [Unit]
          Description=Custom Development Environment Container
          After=network-online.target

          [Container]
          Image=localhost/my-dev-env:latest
          ContainerName=dev-env
          # Hostname removed - unsupported
          Exec=sleep infinity
          Volume=dev-env-data:/workspace
          AddCapability=SYS_PTRACE
          Environment=TZ=${config.time.timeZone}

          [Service]
          Restart=always

          [Install]
          WantedBy=default.target
        '';
      };

      xdg.configFile."containers/systemd/chromium.container" = {
        text = ''
          [Unit]
          Description=Chromium Container
          After=network-online.target

          [Container]
          Image=lscr.io/linuxserver/chromium:latest
          ContainerName=chromium
          PublishPort=127.0.0.1:3004:3000
          PublishPort=127.0.0.1:3005:3001
          Volume=chromium-config:/config
          Environment=PUID=1000
          Environment=PGID=1000
          Environment=TZ=${config.time.timeZone}
          ShmSize=1gb
          # SecurityOpt removed - unsupported

          [Service]
          Restart=always

          [Install]
          WantedBy=default.target
        '';
      };

      xdg.configFile."containers/systemd/emulatorjs.container" = {
        text = ''
          [Unit]
          Description=EmulatorJS Container
          After=network-online.target

          [Container]
          Image=lscr.io/linuxserver/emulatorjs:latest
          ContainerName=emulatorjs
          PublishPort=127.0.0.1:3000:3000
          PublishPort=127.0.0.1:8081:80
          PublishPort=127.0.0.1:4001:4001
          Volume=emulatorjs-config:/config
          Volume=emulatorjs-data:/data
          Environment=PUID=1000
          Environment=PGID=1000
          Environment=TZ=${config.time.timeZone}

          [Service]
          Restart=always

          [Install]
          WantedBy=default.target
        '';
      };

      xdg.configFile."containers/systemd/librewolf.container" = {
        text = ''
          [Unit]
          Description=LibreWolf Container
          After=network-online.target

          [Container]
          Image=lscr.io/linuxserver/librewolf:latest
          ContainerName=librewolf
          PublishPort=127.0.0.1:3001:3000
          Volume=librewolf-config:/config
          Environment=PUID=1000
          Environment=PGID=1000
          Environment=TZ=${config.time.timeZone}
          ShmSize=1gb
          # SecurityOpt removed - unsupported
          # Memory removed - unsupported

          [Service]
          Restart=always

          [Install]
          WantedBy=default.target
        '';
      };

      systemd.user.startServices = true;

      xsession.windowManager.i3 = {
         enable = true;
         config = {
           terminal = "kitty";
           modifier = "Mod4";
           floating.modifier = "Mod4";
         };
         extraConfig = ''
           for_window [class="^.*"] border pixel 0
         '';
      };

    }; # End users.${config.variables.user.name}
  }; # End home-manager
}
