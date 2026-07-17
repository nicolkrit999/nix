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

        # We manage our own ~/.config/nvim. sideloadInitLua makes home-manager
        # NOT write its generated init.lua to disk (so no mkForce conflict), and
        # instead load it via the neovim wrapper's `--cmd 'lua dofile(...)'`,
        # which runs *before* our own init.lua. That generated init is the only
        # place HM sets `g:python3_host_prog`, so this is what makes the python3
        # provider (needed by UltiSnips) actually work. Keeps our dotfiles fully
        # portable - no nix-specific lines leak into ~/.config/nvim.
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
