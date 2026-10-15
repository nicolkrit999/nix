{ delib
, pkgs
, lib
, inputs
, ...
}:

let
  packageLeaves = {
    "claude/common" = [
      ".claude/CLAUDE.md"
      ".claude/RTK.md"
      ".claude/agents"
      ".claude/memory"
      ".claude/notebooklm"
      ".claude/skills"
      ".config/ccstatusline"
    ];

    "claude/mac" = [
      ".claude.json"
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

    "openlogi/Krits-MacBook-Pro" = [
      ".config/openlogi"
    ];
  };

  packagesPerHost = {
    Krits-MacBook-Pro = [
      "claude/common"
      "claude/mac"
      "gsd"
      "devdocs"
      "openlogi/Krits-MacBook-Pro"
    ];
  };

  # Maps home-dir path → repo-relative path, for cases where the two differ
  extraMappingsPerHost = {
    Krits-MacBook-Pro = {
      # ~/.local/bin is on the PATH via home.sessionPath (modules/darwin/toplevel/home-darwin.nix).
      # That only reaches shells that source hm-session-vars: verify on a real Mac that a
      # Claude Code launched from a GUI (Dock/Spotlight) still resolves "start-actual-mcp".
      ".local/bin/start-actual-mcp" = "claude/common/binaries/start-actual-mcp";
      # macOS school workspace has NO leading dot (unlike NixOS .school-workspace).
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.claude/agents" = "claude/momentary/.claude/agents";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      "school-workspace/.claude/skills" = "claude/school/.claude/skills";
      "school-workspace/.claude/agents" = "claude/school/.claude/agents";
      "school-workspace/.mcp.json" = "claude/school/.mcp.json";
    };
  };

  # Home paths that GUIs rewrite in place (replacing the symlink with a regular
  # file/dir); their live content is copied back into the repo before HM relinks.
  syncBack = [
    ".config/openlogi"
  ];
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

      syncBackEntries = lib.filter (p: mappings ? ${p}) syncBack;

      coreutils = "${pkgs.coreutils}/bin";
      diffutils = "${pkgs.diffutils}/bin";

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
          repo_root="${homeDir}/dotfiles-private"

          sync_back() {
            live="${homeDir}/$1"
            repo="$repo_root/$2"
            [ -L "$live" ] && return 0
            if [ -f "$live" ]; then
              [ -d "$(${coreutils}/dirname "$repo")" ] || return 0
              [ -d "$repo" ] && return 0
              if ! ${diffutils}/cmp -s "$live" "$repo"; then
                run ${coreutils}/cp -f "$live" "$repo.syncback.tmp" \
                  && run ${coreutils}/mv -f "$repo.syncback.tmp" "$repo" \
                  || { run ${coreutils}/rm -f "$repo.syncback.tmp"; return 0; }
              fi
              run ${coreutils}/rm -f "$live"
            elif [ -d "$live" ]; then
              [ -d "$repo" ] && [ ! -L "$repo" ] || return 0
              if ! ${diffutils}/diff -rq "$live" "$repo" >/dev/null 2>&1; then
                # --delete mirrors removals into the repo: a GUI that rewrote only
                # part of the dir would delete the other tracked files from it.
                run ${pkgs.rsync}/bin/rsync -a --delete "$live"/ "$repo"/ || return 0
              fi
              run ${coreutils}/rm -rf "$live"
            fi
          }

          ${syncBackScript}
          true
        '';
    };
}
