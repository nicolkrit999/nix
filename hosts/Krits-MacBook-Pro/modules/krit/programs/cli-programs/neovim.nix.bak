{ delib, pkgs, lib, ... }:
delib.module {
  name = "krit.programs.neovim";

  options.krit.programs.neovim = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { ... }:
    {
      home.packages = (
        with pkgs;
        [
          nodejs # Ensure it's installed to allow copilot.lua to work
        ]
      );

      programs.neovim = {

        enable = true;
        viAlias = true;
        vimAlias = true;

        extraPackages = with pkgs; [

          ripgrep
          fd
          xclip

          # --- Language Servers (LSP) ---
          bash-language-server # Bash Language Server
          lua-language-server # Lua Language Server
          marksman # Markdown Language Server
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
    };
}
