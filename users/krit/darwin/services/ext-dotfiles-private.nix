{ delib
, pkgs
, lib
, ...
}:

let
  packageLeaves = {
    "claude/common" = [
      ".claude/agents"
      ".claude/memory"
      ".claude/notebooklm"
      ".claude/skills"
      ".claude/projects/-home-krit-nix/memory"
      ".claude/projects/-home-krit-momentary-gym-claude-skill/memory"
      ".claude/projects/-home-krit-github-repos-personal-portainer-templates/memory"
      ".config/ccstatusline"
      ".claude/RTK.md"
    ];

    "claude/mac" = [
      ".claude.json"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
      ".claude/plans"
    ];

    gsd = [
      ".gsd"
    ];
  };

  packagesPerHost = {
    Krits-MacBook-Pro = [
      "claude/common"
      "claude/mac"
      "gsd"
    ];
  };

  # Maps home-dir path → repo-relative path, for cases where the two differ
  # (e.g. macOS uses ~/bin/ but the file lives under .local/bin/ in the common package)
  extraMappingsPerHost = {
    Krits-MacBook-Pro = {
      "bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
    };
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
      extraMappings = extraMappingsPerHost.${hostname} or { };

      mkLink = relPath:
        pkgs.runCommandLocal
          ("dotfiles-private-" + lib.strings.sanitizeDerivationName relPath)
          { }
          "ln -s ${lib.escapeShellArg "${homeDir}/dotfiles-private/${relPath}"} $out";

      packageMappings = lib.foldl'
        (acc: pkg:
          acc // lib.listToAttrs (map
            (leaf: {
              name = leaf;
              value = "${pkg}/${leaf}";
            })
            packageLeaves.${pkg}))
        { }
        enabledPackages;

      mappings = packageMappings // extraMappings;
    in
    {
      home.file = builtins.mapAttrs
        (_: relPath: { source = mkLink relPath; force = true; })
        mappings;
    };
}
