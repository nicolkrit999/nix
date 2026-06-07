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
      ".config/ccstatusline"
      ".claude/RTK.md"
    ];

    "claude/mac" = [
      ".claude.json"
      ".claude/settings.json"
      ".claude/plans"
      ".claude-mem"
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
      # Scoped skills/MCPs load only inside their context dir (symlinks resolve to claude/parked/*).
      # macOS school workspace has NO leading dot (unlike NixOS .school-workspace).
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      "school-workspace/.claude/skills" = "claude/school/.claude/skills";
      "school-workspace/.claude/agents/cs-study-portfolio.md" = "claude/school/.claude/agents/cs-study-portfolio.md";
      "school-workspace/.mcp.json" = "claude/school/.mcp.json";
      ".claude/projects/-Volumes-nicol-nas-webdav-owncloud-University/memory" = "claude/common/.claude/projects/nicol-nas-webdav-owncloud-University/memory";
      ".claude/projects/-Users-krit-nix/memory" = "claude/common/.claude/projects/nix/memory";
      ".claude/projects/-Users-krit-momentary-gym-claude-skill/memory" = "claude/common/.claude/projects/momentary-gym-claude-skill/memory";
      ".claude/projects/-Users-krit-github-repos-personal-portainer-templates/memory" = "claude/common/.claude/projects/github-repos-personal-portainer-templates/memory";
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
