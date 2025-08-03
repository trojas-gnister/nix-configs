{ config, lib, pkgs, ... }:
let
  # Extract values from NixOS config to pass to Home Manager
  hostname = config.variables.networking.hostname;
  
  # Script to set up the steam container after creation
  setupSteamScript = pkgs.writeShellScriptBin "setup-steam-distrobox" ''
    set -e
    echo "Setting up Steam container..."
    
    # Ensure host export directories exist
    mkdir -p "$HOME/.local/share/applications" "$HOME/.local/bin"
    
    # Check if container exists
    if ! ${pkgs.distrobox}/bin/distrobox list | grep -q steam-arch; then
      echo "Creating steam-arch container..."
      ${pkgs.distrobox}/bin/distrobox assemble create --file $HOME/.config/distrobox/distrobox.ini
    fi
    
    echo "Setting up multilib and installing Steam + Sunshine..."
    
    # Add multilib repository (idempotent)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- sudo bash -c '
      if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "" >> /etc/pacman.conf
        echo "[multilib]" >> /etc/pacman.conf
        echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
      fi
    '
    
    # Update package database
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- sudo pacman -Sy
    
    # Install Steam and gaming packages (official repos)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- sudo pacman -S --needed --noconfirm steam lib32-mesa lib32-vulkan-radeon lib32-libglvnd lib32-openal ttf-liberation gamescope
    
    # Install yay AUR helper if not present (run as user)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- bash -c '
      if ! command -v yay &> /dev/null; then
        git clone https://aur.archlinux.org/yay.git ~/yay-temp
        cd ~/yay-temp
        makepkg -si --noconfirm
        cd ~
        rm -rf yay-temp
      fi
    '
    
    # Install Sunshine from AUR (with CUDA disabled for AMD)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- yay -S --noconfirm sunshine _use_cuda=false
    
    # Set permissions and capabilities in container
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- sudo usermod -aG video,input $USER
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- sudo setcap cap_sys_admin+ep /usr/bin/sunshine || echo "Note: setcap failed, Sunshine will use software encoding"
    
    # Export Steam (use --app for desktop integration)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- env XDG_DATA_DIRS=/usr/share:/usr/local/share:$HOME/.local/share distrobox-export --app steam --delete || true
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- env XDG_DATA_DIRS=/usr/share:/usr/local/share:$HOME/.local/share distrobox-export --app steam
    
    # Export Sunshine (use --bin since no .desktop file)
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- env XDG_DATA_DIRS=/usr/share:/usr/local/share:$HOME/.local/share distrobox-export --bin /usr/bin/sunshine --delete || true
    ${pkgs.distrobox}/bin/distrobox enter -n steam-arch -- env XDG_DATA_DIRS=/usr/share:/usr/local/share:$HOME/.local/share distrobox-export --bin /usr/bin/sunshine
    
    echo "Steam and Sunshine container setup completed!"
    echo "You can now run 'steam' and 'sunshine' from your host system."
    echo "Configure Sunshine at https://localhost:47990"
  '';
in
{
  # Install Distrobox and our setup script
  home-manager.users.${config.variables.user.name} = { config, lib, pkgs, ... }: {
    home.packages = [ 
      pkgs.distrobox 
      setupSteamScript
    ];
    
    # Generate distrobox.ini for declarative container management
    xdg.configFile."distrobox/distrobox.ini".text = ''
      [steam-arch]
      image=archlinux:latest
      init=true
      additional_packages=base-devel git
      pull=true
      replace=true
      nvidia=false
      root=false
      additional_flags=--device /dev/dri:/dev/dri --device /dev/uinput:/dev/uinput --device /dev/input:/dev/input --group-add 988  # GPU and input passthrough with container-devices group (988)
    '';
    
    # Generate basic sunshine.conf with AMD-specific settings
    xdg.configFile."sunshine/sunshine.conf".text = ''
      # Basic Sunshine config for AMD GPU streaming
      sunshine_name = ${hostname}-container
      min_log_level = info
      encoder = amf  # Use AMF for AMD GPU encoding
      adapter_name = /dev/dri/renderD128  # AMD render node
      bitrate = 50000  # 50 Mbps default
      port = 47989  # Default HTTPS port
      upnp = on  # Enable UPnP for auto port mapping
    '';

    # Systemd user service for Sunshine (auto-start on graphical session)
    systemd.user.services.sunshine = {
      Unit = {
        Description = "Sunshine self-hosted game stream host for Moonlight";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.home.homeDirectory}/.local/bin/sunshine";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [
          "PATH=/run/current-system/sw/bin:/usr/bin:/bin:${config.home.homeDirectory}/.local/bin"
          "XDG_RUNTIME_DIR=%i"
          "WAYLAND_DISPLAY=wayland-1"
          "DISPLAY=:0"
        ];
      };
    };
  };
}
