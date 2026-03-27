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
      # XDG desktop entries only for NixOS (not relevant on macOS)
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
