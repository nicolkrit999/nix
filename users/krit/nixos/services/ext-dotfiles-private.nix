{ delib
, pkgs
, lib
, inputs
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

    "claude/Nicol-NAS" = [
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

    gsd = [
      ".gsd"
    ];

    # devdocs.nvim offline docs, shared so every host sees the same installed set
    devdocs = [
      ".local/share/nvim/devdocs"
    ];

    "vicinae/common" = [
      ".local/share/vicinae/shortcuts/shortcuts.json"
      ".local/share/vicinae/snippets/snippets.json"
      ".config/vicinae/settings.json"
    ];

    "openlogi/nixos-desktop" = [
      ".config/openlogi"
    ];

    "openlogi/nixos-laptop" = [
      ".config/openlogi"
    ];
  };

  packagesPerHost = {
    nixos-desktop = [
      "claude/common"
      "claude/nixos-desktop"
      "gsd"
      "devdocs"
      "vicinae/common"
      "openlogi/nixos-desktop"
    ];
    nixos-laptop = [
      "claude/common"
      "claude/nixos-laptop"
      "gsd"
      "devdocs"
      "vicinae/common"
      "openlogi/nixos-laptop"
    ];
    Nicol-NAS = [
      "claude/common"
      "claude/Nicol-NAS"
    ];
  };

  # Maps home-dir path → repo-relative path, for cases where the two differ
  extraMappingsPerHost = {
    nixos-desktop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      # Scoped skills/MCPs load only inside their context dir (symlinks resolve to claude/parked/*)
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.claude/agents" = "claude/momentary/.claude/agents";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.claude/agents" = "claude/school/.claude/agents";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
    };
    nixos-laptop = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.claude/agents" = "claude/momentary/.claude/agents";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      ".school-workspace/.claude/skills" = "claude/school/.claude/skills";
      ".school-workspace/.claude/agents" = "claude/school/.claude/agents";
      ".school-workspace/.mcp.json" = "claude/school/.mcp.json";
    };
    Nicol-NAS = {
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
    };
  };

  # Home paths that GUIs rewrite in place (replacing the symlink with a regular
  # file/dir); their live content is copied back into the repo before HM relinks.
  syncBack = [
    ".config/vicinae/settings.json"
    ".config/openlogi"
  ];
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

      syncBackEntries = lib.filter (p: mappings ? ${p}) syncBack;

      syncBackScript = lib.concatMapStringsSep "\n"
        (p: "sync_back ${lib.escapeShellArg p} ${lib.escapeShellArg mappings.${p}}")
        syncBackEntries;
    in
    {
      home.file = builtins.mapAttrs
        (_: relPath: { source = mkLink relPath; force = true; })
        mappings;

      home.activation.syncBackDotfilesPrivate =
        inputs.home-manager.lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils pkgs.rsync ]}:$PATH
          repo_root="${homeDir}/dotfiles-private"

          sync_back() {
            live="${homeDir}/$1"
            repo="$repo_root/$2"
            [ -L "$live" ] && return 0
            if [ -f "$live" ]; then
              [ -d "$(dirname "$repo")" ] || return 0
              [ -d "$repo" ] && return 0
              if ! cmp -s "$live" "$repo"; then
                cp -f "$live" "$repo.syncback.tmp" \
                  && mv -f "$repo.syncback.tmp" "$repo" \
                  || { rm -f "$repo.syncback.tmp"; return 0; }
              fi
              rm -f "$live"
            elif [ -d "$live" ]; then
              [ -d "$repo" ] && [ ! -L "$repo" ] || return 0
              if ! diff -rq "$live" "$repo" >/dev/null 2>&1; then
                rsync -a "$live"/ "$repo"/ || return 0
              fi
              rm -rf "$live"
            fi
          }

          ${syncBackScript}
          true
        '';
    };
}
