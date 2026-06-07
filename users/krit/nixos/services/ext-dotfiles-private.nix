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

    "claude/nixos-desktop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plans"
    ];

    "claude/nixos-laptop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plans"
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
  # (binaries/ is the platform-neutral store; each OS maps it to its own convention)
  extraMappingsPerHost = {
    nixos-desktop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      # Scoped skills/MCPs load only inside their context dir (symlinks resolve to claude/parked/*)
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
      ".claude/projects/-mnt-nicol-nas-webdav-owncloud-University/memory" = "claude/common/.claude/projects/nicol-nas-webdav-owncloud-University/memory";
      ".claude/projects/-home-krit-nix/memory" = "claude/common/.claude/projects/nix/memory";
      ".claude/projects/-home-krit-momentary-gym-claude-skill/memory" = "claude/common/.claude/projects/momentary-gym-claude-skill/memory";
      ".claude/projects/-home-krit-github-repos-personal-portainer-templates/memory" = "claude/common/.claude/projects/github-repos-personal-portainer-templates/memory";
    };
    nixos-laptop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
      ".claude/projects/-mnt-nicol-nas-webdav-owncloud-University/memory" = "claude/common/.claude/projects/nicol-nas-webdav-owncloud-University/memory";
      ".claude/projects/-home-krit-nix/memory" = "claude/common/.claude/projects/nix/memory";
      ".claude/projects/-home-krit-momentary-gym-claude-skill/memory" = "claude/common/.claude/projects/momentary-gym-claude-skill/memory";
      ".claude/projects/-home-krit-github-repos-personal-portainer-templates/memory" = "claude/common/.claude/projects/github-repos-personal-portainer-templates/memory";
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
