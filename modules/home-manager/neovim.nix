{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil
      nixd
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      pyright
      rust-analyzer
      gopls
      bash-language-server
      marksman
      nodePackages.svelte-language-server

      # Formatters
      stylua
      alejandra
      black
      prettierd
      shfmt

      # Tools
      ripgrep
      fd
      fzf
      gcc
      gnumake
      nodejs_22
      tree-sitter
    ];

    extraLuaConfig = ''
      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local out = vim.fn.system({
          "git", "clone", "--filter=blob:none", "--branch=stable",
          "https://github.com/folke/lazy.nvim.git", lazypath,
        })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" } }, true, {})
          vim.cmd("cquit")
        end
      end
      vim.opt.rtp:prepend(lazypath)

      -- LazyVim bootstrap
      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.lang.python" },
          { import = "lazyvim.plugins.extras.lang.rust" },
          { import = "lazyvim.plugins.extras.lang.go" },
          { import = "lazyvim.plugins.extras.lang.nix" },
          { import = "lazyvim.plugins.extras.lang.markdown" },
          { import = "lazyvim.plugins.extras.formatting.prettier" },
          { import = "lazyvim.plugins.extras.ui.mini-animate" },
          { import = "lazyvim.plugins.extras.editor.mini-files" },
          { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
          {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
            opts = {
              flavour = "mocha",
              transparent_background = true,
              integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                notify = true,
                mini = { enabled = true },
                telescope = { enabled = true },
                which_key = true,
                lsp_trouble = true,
                noice = true,
              },
            },
          },
          {
            "LazyVim/LazyVim",
            opts = { colorscheme = "catppuccin" },
          },
        },
        defaults = { lazy = false, version = false },
        install = { colorscheme = { "catppuccin", "habamax" } },
        checker = { enabled = true, notify = false },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
            },
          },
        },
      })
    '';
  };
}
