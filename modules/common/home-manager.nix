{ config, lib, pkgs, ... }:
let
  nixosSystemConfig = config;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${nixosSystemConfig.variables.user.name} = { config, pkgs, lib, ... }:
    let
      hmUserConfig = config;
      userName = nixosSystemConfig.variables.user.name;
      userSystemDefinition = nixosSystemConfig.users.users.${userName};
      headsetMacArctis = "28:9A:4B:FB:92:83";
    in
    {
      home.username = userName;
      home.homeDirectory = userSystemDefinition.home;
      home.stateVersion = "24.11";
      fonts.fontconfig.enable = true;

      home.packages = with pkgs;
        lib.lists.map (pname: lib.getAttr pname pkgs) nixosSystemConfig.variables.packages.homeManager;
      
      xdg.configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';

      services.podman.enable = true;

      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "ls --color=auto";
          grep = "grep --color=auto";
          nvim-py = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/py-dev:noble \
            tmux new
          '';
          nvim-nodejs = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/nodejs-dev:noble \
            tmux new
          '';
          nvim-rust = ''
            podman run -ti --rm \
            -v "$HOME/Development:/development" \
            aghost7/rust-dev:noble \
            tmux new
          '';
          nix-sync-config = "echo 'Backing up old config to ~/nix.bak...' && mkdir -p ~/nix.bak && sudo mv /etc/nixos/{lib,hosts,modules,iso,flake.nix} ~/nix.bak/ && echo 'Copying new config to /etc/nixos...' && sudo cp -r ~/Development/nix-configs/{lib,hosts,modules,iso,flake.nix} /etc/nixos/";
        };
      };

      systemd.user.startServices = true;

      xdg.configFile."containers/storage.conf".text = ''
        [storage]
        driver = "overlay"
        runroot = "/run/user/${toString userSystemDefinition.uid}/containers"
        graphroot = "${userSystemDefinition.home}/.local/share/containers/storage"

        [storage.options.overlay]
        mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
        mountopt = "nodev,metacopy=on"
      '';

    };
  };
}
