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
        { sopsSecret = "claude_mcp_uptime_kuma_username"; }
        { sopsSecret = "claude_mcp_uptime_kuma_password"; }
        { sopsSecret = "claude_mcp_gitea_api_key"; }
        { sopsSecret = "claude_mcp_immich_api_key"; }
        { sopsSecret = "claude_mcp_jellyfin_api_key"; }
        { sopsSecret = "claude_mcp_paperless_api_token"; }
        { sopsSecret = "claude_mcp_tailscale_oauth_client_id"; }
        { sopsSecret = "claude_mcp_tailscale_oauth_client_secret"; }
        { sopsSecret = "claude_mcp_unifi_username"; }
        { sopsSecret = "claude_mcp_unifi_password"; }
        { sopsSecret = "claude_mcp_homebox_api_key"; }
        { sopsSecret = "claude_mcp_adguard_home_username"; }
        { sopsSecret = "claude_mcp_adguard_home_password"; }
        { sopsSecret = "claude_mcp_opencloud_app_token"; }
        { sopsSecret = "claude_mcp_mealie_api_key"; }
        { sopsSecret = "claude_mcp_navidrome_username"; }
        { sopsSecret = "claude_mcp_navidrome_password"; }
        { sopsSecret = "claude_mcp_stirling_pdf_api_key"; }
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
          "__pycache__/"
          "*.pyc"

          # Credentials and cache
          "**/.credentials.json"
          "**/stats-cache.json"
          "**/policy-limits.json"

          # Plugin marketplace clones, caches and counters: local regenerable state
          # (marketplaces/ are embedded git repos that can't be committed).
          "**/.claude/plugins/marketplaces/"
          "**/.claude/plugins/cache/"
          "**/.claude/plugins/blocklist.json"
          "**/.claude/plugins/install-counts-cache.json"

          # Plugin install receipts: host-local, regenerated from enabledPlugins
          # (settings.json); paths point into the ignored local cache.
          "**/.claude/plugins/installed_plugins.json"
          "**/.claude/plugins/known_marketplaces.json"

          # claude-mem: track only claude-mem.db, settings.json and corpora/; the rest
          # is runtime/transient (the WAL alone churns >4MB/session, logs ~2MB/day).
          "**/.claude-mem/claude-mem.db-wal"
          "**/.claude-mem/claude-mem.db-shm"
          "**/.claude-mem/worker.pid"
          "**/.claude-mem/supervisor.json"
          "**/.claude-mem/logs/"
          "**/.claude-mem/backups/"
          "**/.claude-mem/observer-sessions/"
          "**/.claude-mem/.cwd-remap-applied*"
          "**/.claude-mem/.cleanup-*"

          # context-mode: track only content/*.db and sessions/*.db; the rest is
          # runtime/transient (insight-cache is a 379M node_modules+build).
          "**/.claude/context-mode/insight-cache/"
          "**/.claude/context-mode/**/*.db-wal"
          "**/.claude/context-mode/**/*.db-shm"
          "**/.claude/context-mode/sessions/stats-pid-*.json"
          "**/.claude/context-mode/sessions/*-events.md"
          "**/.claude/context-mode/*.log"

          # Cache of the account's Anthropic skills, re-synced by the client on every host.
          "**/.claude/skills/synced/"

          # Per-project data is host-specific (transcripts, subagents/, workflows/,
          # tool-results/, observer sessions); only the per-project memory is tracked.
          "**/.claude/projects/*/*"
          "!**/.claude/projects/*/memory"
          "!**/.claude/projects/*/memory/**"

          # Last on purpose: the memory re-include above would otherwise win for a
          # settings.local.json that sits inside a tracked memory dir.
          "settings.local.json"
        ];
        extraShellAliases = templateAliases;
      };
    };
}
