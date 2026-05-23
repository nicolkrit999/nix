{ delib
, pkgs
, lib
, ...
}:

let
  packageLeaves = {
    claude-ai-common = [
      ".claude/agents"
      ".claude/memory"
      ".claude/notebooklm"
      ".claude/skills"
      ".claude/projects/-home-krit-nix/memory"
      ".claude/projects/-home-krit-momentary-gym-claude-skill/memory"
      ".claude/projects/-home-krit-github-repos-personal-portainer-templates/memory"
      ".config/ccstatusline"
      ".local/bin/start-actual-mcp"
    ];

    claude-ai-private-nixOS-desktop = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plugins/marketplaces"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
      ".claude/plans"
    ];

    claude-ai-private-nixOS-laptop = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plugins/marketplaces"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
      ".claude/plans"
    ];

    gsd = [
      ".gsd"
    ];

    vicinae-common = [
      ".local/share/vicinae/shortcuts/shortcuts.json"
      ".local/share/vicinae/snippets/snippets.json"
    ];

    vicinae-nixos-desktop = [
      ".config/vicinae/settings.json"
    ];

    vicinae-nixos-laptop = [
      ".config/vicinae/settings.json"
    ];
  };

  packagesPerHost = {
    nixos-desktop = [
      "claude-ai-common"
      "claude-ai-private-nixOS-desktop"
      "gsd"
      "vicinae-common"
      "vicinae-nixos-desktop"
    ];
    nixos-laptop = [
      "claude-ai-common"
      "claude-ai-private-nixOS-laptop"
      "gsd"
      "vicinae-common"
      "vicinae-nixos-laptop"
    ];
  };
in

delib.module {
  name = "services.external.dotfiles-private";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      homeDir = "/home/${myconfig.constants.user}";
      hostname = myconfig.constants.hostname;
      enabledPackages = packagesPerHost.${hostname} or [ ];

      mkLink = relPath:
        pkgs.runCommandLocal
          ("dotfiles-private-" + lib.strings.sanitizeDerivationName relPath)
          { }
          "ln -s ${lib.escapeShellArg "${homeDir}/dotfiles-private/${relPath}"} $out";

      mappings = lib.foldl'
        (acc: pkg:
          acc // lib.listToAttrs (map
            (leaf: {
              name = leaf;
              value = "${pkg}/${leaf}";
            })
            packageLeaves.${pkg}))
        { }
        enabledPackages;
    in
    {
      home.file = builtins.mapAttrs
        (_: relPath: { source = mkLink relPath; })
        mappings;
    };
}
