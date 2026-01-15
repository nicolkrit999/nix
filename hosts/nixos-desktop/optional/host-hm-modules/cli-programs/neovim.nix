{ pkgs, lib, ... }:
{
  programs.neovim = {

    enable = true;
    viAlias = true;
    vimAlias = true;
    package = lib.mkForce (lib.hiPrio pkgs.neovim-unwrapped);

    # Extra packages to install for Neovim's backend functionality
    extraPackages = with pkgs; [

      # --- Language Servers (LSP) ---
      bash-language-server # Bash Language Server
      lua-language-server # Lua Language Server
      nixd # Nix language server
      nixpkgs-fmt

      python313Packages.python-lsp-server # Python Language Server
      yaml-language-server # YAML Language Server
      vim-language-server # Vimscript Language Server

      # --- Linters & Formatters ---
      pyright # Static type checker for Python

      # --- Treesitter & Parsers ---
      (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
        p.lua
        p.vim
        p.json
        p.toml
        p.html
        p.hyprlang
        p.regex
      ]))

      # --- Fonts ---
      nerd-fonts.hack # Fonts for icons
      nerd-fonts.jetbrains-mono # JetBrains Mono with icons
    ];
  };
}
