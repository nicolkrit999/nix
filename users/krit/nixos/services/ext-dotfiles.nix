{ delib
, ...
}:

let
  # ---------------------------------------------------------------
  # 🔗 DOTFILES SYMLINK MAP
  # ---------------------------------------------------------------
  # Maps "<path under $HOME>" => "<path relative to ~/dotfiles>"
  # Add new entries here when extending the dotfiles repo.
  # Each entry becomes an out-of-store symlink:
  #   ~/<key>  ->  ~/dotfiles/<value>
  # The dotfiles repo must be cloned at ~/dotfiles or the symlinks
  # will be dangling. This module does NOT clone the repo.
  # ---------------------------------------------------------------
  mappings = {
    # caelestia-shell
    ".config/caelestia" = "caelestia-shell/.config/caelestia";

    # fastfetch (NixOS flavor)
    ".config/fastfetch" = "catppuccin-mocha-fastfetch-nixOS/.config/fastfetch";

    # general-bash
    ".bashrc_custom" = "general-bash/.bashrc_custom";

    # general-fish
    ".config/conf.d" = "general-fish/.config/conf.d";
    ".custom.fish" = "general-fish/.custom.fish";

    # general-nvim
    ".config/nvim" = "general-nvim/.config/nvim";

    # general-zshrc
    ".zshrc_custom" = "general-zshrc/.zshrc_custom";

    # noctalia-shell
    ".config/noctalia" = "noctalia-shell/.config/noctalia";

    # profile-picture
    ".face" = "profile-picture/.face";
  };
in

delib.module {
  name = "services.external.dotfiles";

  options = delib.singleEnableOption false;

  home.ifEnabled = { ... }: {
    imports = [
      ({ config, ... }: {
        home.file = builtins.mapAttrs
          (_: relPath: {
            source = config.lib.file.mkOutOfStoreSymlink
              "${config.home.homeDirectory}/dotfiles/${relPath}";
          })
          mappings;
      })
    ];
  };
}
