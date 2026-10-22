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
      ".claude-mem"
      ".claude/context-mode"
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
      ".local/bin/learn-faster" = "claude/common/binaries/learn-faster";
      # macOS school workspace has NO leading dot (unlike NixOS .school-workspace).
      "momentary/.claude/skills" = "claude/momentary/.claude/skills";
      "momentary/.claude/agents" = "claude/momentary/.claude/agents";
      "momentary/.mcp.json" = "claude/momentary/.mcp.json";
      "school-workspace/.claude/skills" = "claude/school/.claude/skills";
      "school-workspace/.claude/agents" = "claude/school/.claude/agents";
      "school-workspace/.mcp.json" = "claude/school/.mcp.json";
      "momentary/.claude/commands" = "claude/momentary/.claude/commands";
      "momentary/.learning" = "claude/momentary/.learning";
      "school-workspace/.claude/commands" = "claude/school/.claude/commands";
      "school-workspace/.learning" = "claude/school/.learning";
    };
  };

  # Per-project memory shared across hosts. ~/.claude/projects stays a real local
  # dir (transcripts etc. are host-specific); only <encoded-cwd>/memory is linked
  # to claude/common/.claude/projects/<name>/memory. Key = dir name in the repo,
  # value = absolute cwd of the project on this platform.
  projectMemories = homeDir: {
    nix = "${homeDir}/nix";
    dotfiles-private = "${homeDir}/dotfiles-private";
    dotfiles = "${homeDir}/dotfiles";
    github-repos-personal-portainer-templates = "${homeDir}/github-repos/personal/portainer-templates";
    momentary-gym-claude-skill = "${homeDir}/momentary/gym-claude-skill";
  };

  # Claude Code names a project dir after its cwd with every non-alphanumeric char as "-"
  encodeProjectDir = lib.stringAsChars (c: if builtins.match "[A-Za-z0-9]" c != null then c else "-");

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
      linkProjectMemoryScript = lib.concatStringsSep "\n" (lib.mapAttrsToList
        (name: cwd: "link_memory ${lib.escapeShellArg (encodeProjectDir cwd)} ${lib.escapeShellArg name}")
        (projectMemories homeDir));
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

      # Runs after linkGeneration so a stale ~/.claude/projects symlink is already gone.
      home.activation.linkClaudeProjectMemory =
        inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          repo_root="${homeDir}/dotfiles-private"

          link_memory() {
            src="$repo_root/claude/common/.claude/projects/$2/memory"
            dir="${homeDir}/.claude/projects/$1"
            [ -d "$src" ] || return 0
            run ${coreutils}/mkdir -p "$dir"
            if [ -L "$dir/memory" ] || [ ! -e "$dir/memory" ]; then
              run ${coreutils}/ln -sfn "$src" "$dir/memory"
            else
              warnEcho "$dir/memory is a real directory; not replacing it with the shared memory link"
            fi
          }

          ${linkProjectMemoryScript}
          true
        '';

      # settings.json is linked straight into the repo, not through /nix/store: Claude
      # Code rewrites it (/effort etc.) and a store hop in the chain makes that fail
      # with EROFS. Skipped while the shared file does not exist yet.
      home.activation.linkClaudeSettings =
        inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          src="${homeDir}/dotfiles-private/claude/common/.claude/settings.json"
          dst="${homeDir}/.claude/settings.json"
          if [ -f "$src" ]; then
            run ${coreutils}/mkdir -p "${homeDir}/.claude"
            if [ -L "$dst" ] || [ ! -e "$dst" ]; then
              run ${coreutils}/ln -sfn "$src" "$dst"
            else
              warnEcho "$dst is a real file; not replacing it with the shared settings link"
            fi
          fi
        '';
    };
}
