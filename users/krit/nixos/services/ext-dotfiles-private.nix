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

    "claude/nixos-desktop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
      ".claude/plans"
    ];

    "claude/nixos-laptop" = [
      ".claude.json"
      ".claude/keybindings.json"
      ".claude/settings.json"
      ".claude/plugins/installed_plugins.json"
      ".claude/plugins/known_marketplaces.json"
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
    };
    nixos-laptop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
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
