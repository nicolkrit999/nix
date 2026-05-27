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
    ];

    claude-ai-private-macOS = [
      ".claude.json"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
      ".claude/plans"
      "bin/start-actual-mcp"
    ];

    gsd = [
      ".gsd"
    ];
  };

  packagesPerHost = {
    Krits-MacBook-Pro = [
      "claude-ai-common"
      "claude-ai-private-macOS"
      "gsd"
    ];
  };
in

delib.module {
  name = "darwin.services.external.dotfiles-private";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      homeDir = "/Users/${myconfig.constants.user}";
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
        (_: relPath: { source = mkLink relPath; force = true; })
        mappings;
    };
}
