{ delib
, config
, lib
, moduleSystem
, pkgs
, ...
}:
let
  # Deliberately unpinned `@latest`: a manual escape hatch, not a managed tool.
  templateAliases = {
    caitempplugins = "npx claude-code-templates@latest --plugins";
    caitemphealt = "npx claude-code-templates@latest --health-check";
    caitempchat = "npx claude-code-templates@latest --chats";
    caitempanalytics = "npx claude-code-templates@latest --analytics";
  };

  # Claude Code appends a session trailer/URL to commit messages regardless of
  # `attribution`. One dispatcher is installed under every git hook name: it
  # strips the trailer (commit-msg only), then runs the repo's own hook of the
  # same name, since this hooks dir replaces the repo's (global core.hooksPath,
  # and the env override below, which also beats a repo-local core.hooksPath).
  gitHookNames = [
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "pre-commit"
    "pre-merge-commit"
    "prepare-commit-msg"
    "commit-msg"
    "post-commit"
    "pre-rebase"
    "post-checkout"
    "post-merge"
    "pre-push"
    "post-rewrite"
    "reference-transaction"
    "push-to-checkout"
    "pre-auto-gc"
    "post-update"
    "pre-receive"
    "update"
    "proc-receive"
    "post-receive"
    "fsmonitor-watchman"
    "sendemail-validate"
  ];
  hookDispatcher = pkgs.writeShellScript "git-hook-dispatcher" ''
    name="$(${pkgs.coreutils}/bin/basename "$0")"
    if [ "$name" = commit-msg ]; then
      msg="$1"
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.gnused}/bin/sed -E '/^(Claude-Session:|https:\/\/claude\.ai\/code\/session_)/d' "$msg" \
        | ${pkgs.gawk}/bin/awk 'NF { for (i = 0; i < b; i++) print ""; b = 0; print; next } { b++ }' > "$tmp"
      ${pkgs.coreutils}/bin/cat "$tmp" > "$msg"
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    fi
    # Repo's own hooks dir: its local core.hooksPath, else <common-dir>/hooks
    # (rev-parse --git-path would return this dir again and recurse).
    dir="$(${pkgs.git}/bin/git config --local core.hooksPath 2>/dev/null)"
    if [ -z "$dir" ]; then
      dir="$(${pkgs.git}/bin/git rev-parse --git-common-dir 2>/dev/null)/hooks"
    fi
    hook="$dir/$name"
    if [ -x "$hook" ] && [ "$(${pkgs.coreutils}/bin/realpath "$hook")" != "$(${pkgs.coreutils}/bin/realpath "$0")" ]; then
      exec "$hook" "$@"
    fi
  '';
  gitHooksDir = pkgs.linkFarm "claude-git-hooks" (
    map (name: { inherit name; path = hookDispatcher; }) gitHookNames
  );
  # Same rule for GitHub text, which never passes through a git hook: strip the
  # session lines from inline body/notes args and from body/notes files before
  # calling the real gh. Shadows pkgs.gh from the generic git module (hiPrio).
  ghWrapper = pkgs.writeShellScriptBin "gh" ''
    re='^(Claude-Session:|https://claude\.ai/code/session_)'
    gh=${pkgs.gh}/bin/gh
    case "''${1:-}" in
      pr|issue|release|api|discussion) ;;
      *) exec "$gh" "$@" ;;
    esac
    # Created here, not inside strip_file: that runs in a $(...) subshell, so a
    # tmpdir set there would never reach the EXIT trap.
    tmpdir="$(${pkgs.coreutils}/bin/mktemp -d)"
    trap '${pkgs.coreutils}/bin/rm -rf "$tmpdir"' EXIT
    strip_file() {
      out="$tmpdir/$RANDOM"
      if [ "$1" = - ]; then src=/dev/stdin; else src="$1"; fi
      ${pkgs.gnused}/bin/sed -E "\#$re#d" "$src" \
        | ${pkgs.gawk}/bin/awk 'NF { for (i = 0; i < b; i++) print ""; b = 0; print; next } { b++ }' > "$out"
      printf '%s' "$out"
    }
    args=()
    filenext=0
    fieldnext=0
    for a in "$@"; do
      if [ "$filenext" = 1 ]; then
        args+=("$(strip_file "$a")")
        filenext=0
        continue
      fi
      if [ "$fieldnext" = 1 ]; then
        fieldnext=0
        # gh api -F key=@file uploads the file's content
        case "$a" in
          *=@*) args+=("''${a%%=@*}=@$(strip_file "''${a#*=@}")"); continue ;;
        esac
      fi
      case "$a" in
        -F|--field) if [ "$1" = api ]; then fieldnext=1; args+=("$a"); continue; fi ;;
      esac
      case "$a" in
        --body-file|--notes-file) filenext=1; args+=("$a"); continue ;;
        -F) if [ "$1" != api ]; then filenext=1; args+=("$a"); continue; fi ;;
        --body-file=*|--notes-file=*)
          args+=("''${a%%=*}=$(strip_file "''${a#*=}")")
          continue ;;
      esac
      if printf '%s\n' "$a" | ${pkgs.gnugrep}/bin/grep -qE "$re"; then
        a="$(printf '%s\n' "$a" | ${pkgs.gnused}/bin/sed -E "\#$re#d")"
      fi
      args+=("$a")
    done
    "$gh" "''${args[@]}"
  '';
in
delib.module {
  name = "krit.programs.claude-code-personal";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    mcpSecrets = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            sopsSecret = lib.mkOption {
              type = lib.types.str;
              description = "The sops secret name (key in sops.secrets).";
            };
          };
        }
      );
      # Default for every host that does not override it (Nicol-NAS does); the
      # sops declarations on all platforms derive from this list.
      default = [
        { sopsSecret = "openrouter_api_claude_code"; }
        { sopsSecret = "claude_mcp_actual_password"; }
        { sopsSecret = "claude_mcp_actual_sync_id"; }
        { sopsSecret = "claude_mcp_actual_encryption_password"; }
        { sopsSecret = "claude_mcp_context7_api_key"; }
        { sopsSecret = "claude_mcp_openai_api_key"; }
        { sopsSecret = "claude_mcp_milvus_token"; }
        { sopsSecret = "claude_mcp_github_token"; }
        { sopsSecret = "claude_mcp_portainer_token"; }
        { sopsSecret = "claude_mcp_sparkyfitness_api_key"; }
        { sopsSecret = "claude_mcp_vikunja_token"; }
        { sopsSecret = "claude_mcp_beszel_email"; }
        { sopsSecret = "claude_mcp_beszel_password"; }
      ];
      description = "Names of the MCP secrets; the sops declarations are generated from this list in sops-secrets.nix, MCP launchers read the secret files themselves.";
    };
    mcpEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        ACTUAL_SERVER_URL = "https://budget.nicolkrit.ch";
      };
      description = "Static environment variables fed to programs.claude-code.extraEnv (exported by the home-build `claude` wrapper).";
    };
  };

  home.ifEnabled = _: {
    home.packages = [ (lib.hiPrio ghWrapper) ];
    programs.git.settings.core.hooksPath = "${gitHooksDir}";
    # Command-line config outranks a repo-local core.hooksPath, so the strip
    # also runs in repos that set their own (the dispatcher chains to theirs).
    home.sessionVariables = {
      GIT_CONFIG_COUNT = "1";
      GIT_CONFIG_KEY_0 = "core.hooksPath";
      GIT_CONFIG_VALUE_0 = "${gitHooksDir}";
    };
  };

  myconfig.ifEnabled =
    { cfg, ... }:
    let
      hasSecret = name: lib.any (s: s.sopsSecret == name) cfg.mcpSecrets;
      secretPath = name: config.sops.secrets.${name}.path;

      # Standalone home reads the HM sops path; the key stays in env, off argv.
      mcpLaunchers = lib.optionals (moduleSystem == "home") (
        lib.optional (hasSecret "claude_mcp_context7_api_key")
          (
            pkgs.writeShellScriptBin "claude-mcp-context7" ''
              CONTEXT7_API_KEY="$(cat ${lib.escapeShellArg (secretPath "claude_mcp_context7_api_key")})"
              export CONTEXT7_API_KEY
              PATH=${pkgs.nodejs_latest}/bin:$PATH exec npx -y @upstash/context7-mcp
            ''
          )
        ++ lib.optional (hasSecret "claude_mcp_github_token") (
          pkgs.writeShellScriptBin "claude-mcp-github" ''
            AUTH_HEADER="Bearer $(cat ${lib.escapeShellArg (secretPath "claude_mcp_github_token")})"
            export AUTH_HEADER
            PATH=${pkgs.nodejs_latest}/bin:$PATH exec npx mcp-remote https://api.githubcopilot.com/mcp --header 'Authorization:''${AUTH_HEADER}'
          ''
        )
      );
    in
    {
      programs.claude-code = {
        extraEnv = cfg.mcpEnv;
        extraPackages = mcpLaunchers;
        extraGitIgnores = [
          ".worker-clean-shutdown"
          "claude-mem.db*"
          "chroma-sync-state.json"
          "backfill.json"
          "telemetry.json"
          "hook-failures.json"
          "credentials.json"
          "security_warnings_*.json"

        ];
        extraShellAliases = templateAliases;
      };
    };
}
