{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.programs.neovim";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      xdg.desktopEntries.custom-nvim = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
      };

      home.sessionVariables = {
        NVIM_BASE16_THEME = myconfig.constants.theme.base16Theme;
      };

      home.packages = with pkgs; [
        nodejs_latest # nvim :run on .js/.ts and markdown-preview.nvim build
        neovide # GUI frontend; must be in the profile, extraPackages only reaches nvim's own PATH
      ];

      programs.neovim = {
        enable = true;
        package = pkgs.neovim-unwrapped;
        viAlias = true;
        vimAlias = true;
        withRuby = false;
        withPython3 = true; # builds python env + pynvim; wired via sideloadInitLua

        sideloadInitLua = true;

        extraWrapperArgs = [
          "--set"
          "SNACKS_SQLITE3_PATH"
          "${pkgs.sqlite.out}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}"
        ];

        extraPackages = with pkgs; [
          # --- Core tools ---
          curl
          fd
          fzf
          git
          python3Packages.pylatexenc
          ripgrep
          universal-ctags
        ]
        # wl-clipboard and xdg-utils are Linux-only
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          wl-clipboard
          xdg-utils
        ]
        ++ [
          # --- Language Servers (LSP) ---
          bash-language-server
          ltex-ls-plus
          lua-language-server
          marksman
          nixd
          pyright
          typos-lsp
          yaml-language-server

          # --- Formatters ---
          clang-tools
          gofumpt
          google-java-format
          gotools
          libxml2.bin
          nixpkgs-fmt
          prettier
          ruff
          rustfmt
          shfmt
          sql-formatter
          stylua
          taplo
          (texlive.withPackages (ps: [ ps.latexindent ]))
          typstyle
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
            p.asm
            p.bash
            p.c
            p.c_sharp
            p.comment
            p.cpp
            p.css
            p.diff
            p.dockerfile
            p.dtd
            p.fish
            p.git_config
            p.git_rebase
            p.gitcommit
            p.go
            p.haskell
            p.html
            p.hyprlang
            p.java
            p.javascript
            p.jsdoc
            p.json
            p.julia
            p.kotlin
            p.latex
            p.lua
            p.make
            p.markdown
            p.markdown_inline
            p.nix
            p.php
            p.php_only
            p.python
            p.r
            p.regex
            p.ruby
            p.rust
            p.scala
            p.sql
            p.swift
            p.toml
            p.tsx
            p.typescript
            p.typst
            p.vim
            p.xml
            p.yaml
            p.zig
          ]))
        ];
      };
    };
}
