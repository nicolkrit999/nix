{ delib
, pkgs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.neovim";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      isNixOS = moduleSystem == "nixos";
    in
    {
      xdg.desktopEntries.custom-nvim = lib.mkIf isNixOS (lib.mkForce {
        name = "Neovim";
        genericName = "Text Editor";
        exec = "${
          pkgs.${myconfig.constants.terminal.name}
        }/bin/${myconfig.constants.terminal.name} --class nvim -e nvim %F";
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
      });

      home.sessionVariables = {
        NVIM_BASE16_THEME = myconfig.constants.theme.base16Theme;
      };

      home.packages = with pkgs; [
        nodejs_latest # Ensure it's installed to allow copilot.lua to work
      ];

      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        withRuby = false;
        withPython3 = true; # builds python env + pynvim; wired via sideloadInitLua

        sideloadInitLua = true;

        extraPackages = with pkgs; [
          ripgrep
          fd
        ]
        # xclip is Linux-only
        ++ lib.optionals isNixOS [ xclip ]
        ++ [

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

          # --- Fonts ---
          nerd-fonts.hack
          nerd-fonts.jetbrains-mono
        ];

        # NOTE: grammar/plugin packages MUST go through `plugins`, not
        # `extraPackages`. `extraPackages` only prepends to $PATH (fine for
        # CLI tools/LSPs), it never touches packpath/runtimepath. `plugins`
        # is wired onto packpath via home-manager's unconditional
        # `xdg.dataFile."nvim/site/pack/hm"` link (~/.local/share/nvim/site/pack/hm),
        # which Neovim auto-loads at startup regardless of
        # `sideloadInitLua` (that option only affects init.lua sideloading,
        # not the packpath symlink).
        plugins = [
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
            p.lua
            p.vim
            p.json
            p.toml
            p.html
            p.hyprlang
            p.regex
            p.python
            p.javascript
            p.typescript
            p.tsx
            p.java
            p.c
            p.cpp
            p.rust
            p.go
            p.ruby
            p.c_sharp
            p.php
            p.php_only
            p.bash
            p.sql
            p.yaml
            p.latex
            p.nix
            p.css
            p.xml
            p.markdown
            p.markdown_inline
            p.jsdoc
            p.comment
            p.dtd
            p.typst
            p.haskell
            p.kotlin
            p.swift
            p.scala
            p.r
            p.julia
            p.zig
            p.asm
            p.fish
            p.make
            p.dockerfile
          ]))
        ];
      };
    };

}
