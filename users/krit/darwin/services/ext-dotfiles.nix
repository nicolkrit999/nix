{ delib
, pkgs
, lib
, ...
}:

let
  mappings = {
    # fastfetch (macOS flavor)
    ".config/fastfetch" = "macOS/fastfetch/.config/fastfetch";

    # general-bash
    ".bashrc_custom" = "general/shells/.bashrc_custom";

    # general-fish
    ".config/conf.d" = "general/shells/.config/conf.d";
    ".custom.fish" = "general/shells/.custom.fish";

    # general-nvim
    ".config/nvim" = "general/general-nvim/.config/nvim";

    # general-zshrc
    ".zshrc_custom" = "general/shells/.zshrc_custom";
  };
in

delib.module {
  name = "darwin.services.external.dotfiles";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      homeDir = "/Users/${myconfig.constants.user}";
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
