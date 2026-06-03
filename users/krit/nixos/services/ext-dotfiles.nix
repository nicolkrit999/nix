{ delib
, pkgs
, lib
, ...
}:

let
  mappings = {
    # caelestia-shell
    ".config/caelestia" = "linux/linux-general/shells/quickshell/.config/caelestia";

    # noctalia-shell
    ".config/noctalia" = "linux/linux-general/shells/quickshell/.config/noctalia";

    # fastfetch (NixOS flavor)
    ".config/fastfetch" = "linux/linux-distro-specific/nixOS/catppuccin-mocha-fastfetch-nixOS/.config/fastfetch";

    # general-bash
    ".bashrc_custom" = "general/shells/.bashrc_custom";

    # general-fish
    ".config/conf.d" = "general/shells/.config/conf.d";
    ".custom.fish" = "general/shells/.custom.fish";

    # general-nvim
    ".config/nvim" = "general/general-nvim/.config/nvim";

    # general-zshrc
    ".zshrc_custom" = "general/shells/.zshrc_custom";


    # profile-picture
    ".face" = "linux/linux-general/profile-picture/.face";
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
      mkAbsLink = absPath:
        pkgs.runCommandLocal
          ("link-" + lib.strings.sanitizeDerivationName absPath)
          { }
          "ln -s ${lib.escapeShellArg absPath} $out";
    in
    {
      home.file = builtins.mapAttrs (_: relPath: { source = mkLink relPath; force = true; }) mappings // {
        # wallpapers repo (landscape / portrait / various directly inside)
        "Pictures/wallpapers" = { source = mkAbsLink "${homeDir}/github-repos/personal/wallpapers-repo"; force = true; };
      };
    };
}
