{ config, lib, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
  };
in
{
  imports = [
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # System configuration
  networking.hostName = "dev";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  time.timeZone = "America/Chicago"; 

  # Services
  services.openssh.enable = true;

  # Programs
  programs.git.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    xclip
    python3
    gcc
    tmux
    rustup
    nodejs_22
    wl-clipboard
    openvpn
    android-tools
  ];

  # Home Manager configuration
  home-manager.users.nixos = { pkgs, ... }: {
    home.stateVersion = "24.11";

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
  };

  # System state version
  system.stateVersion = "24.11";

  # User configuration
  users.users.nixos = {
    isNormalUser = true;
    uid = 1000;
    group = "users";
    extraGroups = [ "wheel" ];
    home = "/home/nixos";
    shell = pkgs.bash; 
  };
}
