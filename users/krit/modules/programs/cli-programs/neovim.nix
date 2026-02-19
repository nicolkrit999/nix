{
  delib,
  pkgs,
  config,
  lib,
  ...
}:
delib.module {
  name = "krit-nvim";
  options.krit.programs.neovim.enable = delib.boolOption true;

  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      xdg.desktopEntries.custom-nvim = lib.mkForce {
        name = "Neovim";
        genericName = "Text Editor";
        exec = "${pkgs.${myconfig.constants.term}}/bin/${myconfig.constants.term} --class nvim -e nvim %F";
        terminal = false;
        icon = "nvim";
        startupNotify = true;
        settings = {
          StartupWMClass = "nvim";
        };
        categories = [
          "Utility"
          "TextEditor"
        ];
      };

      home.packages = with pkgs; [
        nodejs # Ensure it's installed to allow copilot.lua to work
      ];

      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;

        extraPackages = with pkgs; [
          ripgrep
          fd
          xclip

          # --- Language Servers (LSP) ---
          bash-language-server
          lua-language-server
          nixd
          nixpkgs-fmt
          python313Packages.python-lsp-server
          yaml-language-server
          vim-language-server

          # --- Linters & Formatters ---
          pyright

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
          nerd-fonts.hack
          nerd-fonts.jetbrains-mono
        ];
      };
    };
}
