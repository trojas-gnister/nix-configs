{ userName, dataDevice }:
{ config, lib, pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems."/mnt/data" = {
    device = dataDevice;
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 47984 47989 47990 48010 ];
      allowedUDPPortRanges = [
        { from = 47998; to = 48000; }
        { from = 8000; to = 8010; }
      ];
    };
  };

  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    git.enable = true;
    steam = {
      gamescopeSession.enable = true;
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          libkrb5
          keyutils
        ];
      };
    };
  };

  hardware.opengl.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "libretro-snes9x"
    "libretro-beetle-psx-hw"
    "libretro-genesis-plus-gx"
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
    "nvidia-x11"
    "nvidia-settings"
  ];

  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };

    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = userName;
        };
        sddm.enable = true;
      };
      windowManager = {
        i3 = {
          enable = true;
          extraPackages = with pkgs; [
            dmenu
            i3status
            i3lock
            i3blocks
          ];
        };
      };
    };

    openssh.enable = true;
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      android-tools
      neovim
      git
      xclip
      python3
      gcc
      tmux
      rustup
      nodejs_22
      mangohud
      protonup-qt
      lutris
      bottles
      heroic
      neovim
      sunshine
      spice-autorandr
      spice-vdagent
      wl-clipboard
      openvpn
      kitty
    ];
    variables = {
      GTK_THEME = "Adwaita:dark";
    };
  };

  home-manager.users."${userName}" = { pkgs, ... }: {
    home.stateVersion = "24.11";
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        terminal = "kitty";
      };
      extraConfig = ''
        set $mod Mod1
        font pango:DejaVu Sans Mono 8
        floating_modifier $mod
        exec steam
        exec sunshine
        exec spice-vdagent -x -d
        for_window [class="^.*"] border pixel 0
      '';
    };

    programs.neovim = {
      enable = true;
      extraLuaConfig = ''
        vim.g.mapleader = ' '

        vim.opt.number = true
        vim.opt.relativenumber = true

        vim.opt.tabstop = 4
        vim.opt.shiftwidth = 4
        vim.opt.expandtab = true

        vim.opt.mouse = 'a'
        vim.opt.clipboard = 'unnamedplus'

        vim.opt.termguicolors = true

        local keymap = vim.api.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        -- Setup lazy.nvim
        local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
        if not vim.loop.fs_stat(lazypath) then
          vim.fn.system({
            'git',
            'clone',
            '--filter=blob:none',
            'https://github.com/folke/lazy.nvim.git',
            '--branch=stable',
            lazypath,
          })
        end
        vim.opt.rtp:prepend(lazypath)

        -- Plugins
        require('lazy').setup({
          {
            'nvim-treesitter/nvim-treesitter',
            build = ':TSUpdate',
            config = function()
              require('nvim-treesitter.configs').setup({
                ensure_installed = { 'lua', 'javascript', 'python', 'html', 'css', 'rust', 'nix' },
                highlight = { enable = true },
              })
            end,
          },
          {
            'folke/tokyonight.nvim',
            priority = 1000,
            config = function()
              require('tokyonight').setup({
                style = 'night',
                transparent = true,
                terminal_colors = true,
              })
              vim.cmd('colorscheme tokyonight')
            end,
          },
          {
            'williamboman/mason.nvim',
            build = ':MasonUpdate',
            config = function() require('mason').setup() end,
          },
          {
            'williamboman/mason-lspconfig.nvim',
            dependencies = { 'neovim/nvim-lspconfig' },
            config = function()
              local mason_lspconfig = require('mason-lspconfig')
              mason_lspconfig.setup({
                ensure_installed = {
                  'lua_ls', 'tsserver', 'pyright', 'html', 'cssls', 'rust_analyzer', 'nil_ls'
                },
              })

              local lspconfig = require('lspconfig')
              mason_lspconfig.setup_handlers({
                function(server_name)
                  lspconfig[server_name].setup({})
                end,
              })
            end,
          },
          {
            'folke/which-key.nvim',
            config = function() require('which-key').setup({}) end,
          },
          {
            'nvim-tree/nvim-web-devicons',
            config = function() require('nvim-web-devicons').setup({}) end,
          },
        })

        -- Transparency settings
        vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
        vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

        -- LSP Keybindings
        keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
        keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        keymap('n', '<leader>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)

        -- Register keybindings with which-key
        require('which-key').register({
          ["<leader>"] = {
            ca = { "<cmd>lua vim.lsp.buf.code_action()<CR>", "Code Action" },
            f = { "<cmd>lua vim.lsp.buf.format({ async = true })<CR>", "Format Document" },
            rn = { "<cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" },
          },
          gd = { "<cmd>lua vim.lsp.buf.definition()<CR>", "Go to Definition" },
          gr = { "<cmd>lua vim.lsp.buf.references()<CR>", "Show References" },
        })
      '';
    };

    xdg = {
      enable = true;
      configFile."gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name = Adwaita-dark
      '';
    };
  };

  environment.pathsToLink = [ "/libexec" ];
  users.users."${userName}" = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/${userName}";
    shell = pkgs.bash;
  };
}

