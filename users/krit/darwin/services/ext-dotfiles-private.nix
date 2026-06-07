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
      ".claude/CLAUDE.md"
    ];

    "claude/mac" = [
      ".claude.json"
      ".claude/settings.json"
      ".claude/plans"
      ".claude-mem"
      ".claude/context-mode"
      # Whole projects dir → host. Auto-captures every (future) project; common
      ".claude/projects"
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
  extraMappingsPerHost = {
    Krits-MacBook-Pro = {
      "bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      # macOS school workspace has NO leading dot (unlike NixOS .school-workspace).
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      "school-workspace/.claude/skills" = "claude/school/.claude/skills";
      "school-workspace/.claude/agents/cs-study-portfolio.md" = "claude/school/.claude/agents/cs-study-portfolio.md";
      "school-workspace/.mcp.json" = "claude/school/.mcp.json";
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
