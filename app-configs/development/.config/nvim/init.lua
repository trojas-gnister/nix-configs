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

require('lazy').setup({
  -- Treesitter for syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'javascript', 'python', 'html', 'css', 'rust', 'nix' },
        highlight = {
          enable = true,
        },
      })
    end,
  },

  -- Tokyonight theme for a modern transparent look
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

  -- Mason for managing LSP servers, linters, and formatters
  {
    'williamboman/mason.nvim',
    build = ':MasonUpdate', -- Update registry contents
    config = function()
      require('mason').setup()
    end,
  },

  -- Mason-LSPconfig for easier LSP server setup
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      local mason_lspconfig = require('mason-lspconfig')

      -- Ensure LSP servers are installed
      mason_lspconfig.setup({
        ensure_installed = {
          'lua_ls',         -- Lua
          'tsserver',       -- JavaScript/TypeScript
          'pyright',        -- Python
          'html',           -- HTML
          'cssls',          -- CSS
          'rust_analyzer',  -- Rust
          'nil_ls',         -- Nix
        },
      })

      -- Configure LSP servers
      local lspconfig = require('lspconfig')
      mason_lspconfig.setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({})
        end,
      })
    end,
  },

  -- Which-key for keybinding hints
  {
    'folke/which-key.nvim',
    config = function()
      require('which-key').setup({})
    end,
  },

  -- Web Devicons for better icon support
  {
    'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-web-devicons').setup({})
    end,
  },
})

-- Additional transparency settings
vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })

-- LSP keybindings
keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts) -- Go to definition
keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts) -- Show references
keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)       -- Show hover info
keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts) -- Rename symbol
keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts) -- Code actions
keymap('n', '<leader>f', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts) -- Format document

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
