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

    "claude/nixos-desktop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plans"
      ".claude-mem"
      ".claude/context-mode"
      # Whole projects dir → host. Auto-captures every (future) project; common
      # projects keep a committed memory symlink → claude/common/ inside the repo.
      ".claude/projects"
    ];

    "claude/nixos-laptop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plans"
      ".claude-mem"
      ".claude/context-mode"
      ".claude/projects"
    ];

    gsd = [
      ".gsd"
    ];

    "vicinae/common" = [
      ".local/share/vicinae/shortcuts/shortcuts.json"
      ".local/share/vicinae/snippets/snippets.json"
    ];

    "vicinae/nixos-desktop" = [
      ".config/vicinae/settings.json"
    ];

    "vicinae/nixos-laptop" = [
      ".config/vicinae/settings.json"
    ];
  };

  packagesPerHost = {
    nixos-desktop = [
      "claude/common"
      "claude/nixos-desktop"
      "gsd"
      "vicinae/common"
      "vicinae/nixos-desktop"
    ];
    nixos-laptop = [
      "claude/common"
      "claude/nixos-laptop"
      "gsd"
      "vicinae/common"
      "vicinae/nixos-laptop"
    ];
  };

  # Maps home-dir path → repo-relative path, for cases where the two differ
  extraMappingsPerHost = {
    nixos-desktop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      # Scoped skills/MCPs load only inside their context dir (symlinks resolve to claude/parked/*)
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.claude/agents/cs-study-portfolio.md" = "claude/school/.claude/agents/cs-study-portfolio.md";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
    };
    nixos-laptop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.claude/agents/cs-study-portfolio.md" = "claude/school/.claude/agents/cs-study-portfolio.md";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
    };
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
