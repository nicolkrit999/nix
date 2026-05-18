{ delib
, pkgs
, lib
, ...
}:

let
  mappings = {
    # caelestia-shell
    ".config/caelestia" = "quickshell/.config/caelestia";

    # fastfetch (NixOS flavor)
    ".config/fastfetch" = "catppuccin-mocha-fastfetch-nixOS/.config/fastfetch";

    # general-bash
    ".bashrc_custom" = "shells/.bashrc_custom";

    # general-fish
    ".config/conf.d" = "shells/.config/conf.d";
    ".custom.fish" = "shells/.custom.fish";

    # general-nvim
    ".config/nvim" = "general-nvim/.config/nvim";

    # general-zshrc
    ".zshrc_custom" = "shells/.zshrc_custom";

    # noctalia-shell
    ".config/noctalia" = "quickshell/.config/noctalia";

    # profile-picture
    ".face" = "profile-picture/.face";
  };
in

delib.module {
  name = "services.external.dotfiles";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      homeDir = "/home/${myconfig.constants.user}";
      mkLink = relPath:
        pkgs.runCommandLocal
          ("dotfiles-" + lib.strings.sanitizeDerivationName relPath)
          { }
          "ln -s ${lib.escapeShellArg "${homeDir}/dotfiles/${relPath}"} $out";
    in
    {
      home.file = builtins.mapAttrs (_: relPath: { source = mkLink relPath; }) mappings;
    };
}
