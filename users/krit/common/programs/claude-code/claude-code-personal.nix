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
      type = lib.types.listOf (lib.types.submodule {
        options = {
          sopsSecret = lib.mkOption {
            type = lib.types.str;
            description = "The sops secret name (key in sops.secrets).";
          };
        };
      });
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

  myconfig.ifEnabled = { cfg, ... }:
    let
      hasSecret = name: lib.any (s: s.sopsSecret == name) cfg.mcpSecrets;
      secretPath = name: config.sops.secrets.${name}.path;

      # Standalone home reads the HM sops path; the key stays in env, off argv.
      mcpLaunchers = lib.optionals (moduleSystem == "home") (
        lib.optional (hasSecret "claude_mcp_context7_api_key")
          (pkgs.writeShellScriptBin "claude-mcp-context7" ''
            CONTEXT7_API_KEY="$(cat ${lib.escapeShellArg (secretPath "claude_mcp_context7_api_key")})"
            export CONTEXT7_API_KEY
            PATH=${pkgs.nodejs_latest}/bin:$PATH exec npx -y @upstash/context7-mcp
          '')
        ++ lib.optional (hasSecret "claude_mcp_github_token")
          (pkgs.writeShellScriptBin "claude-mcp-github" ''
            AUTH_HEADER="Bearer $(cat ${lib.escapeShellArg (secretPath "claude_mcp_github_token")})"
            export AUTH_HEADER
            PATH=${pkgs.nodejs_latest}/bin:$PATH exec npx mcp-remote https://api.githubcopilot.com/mcp --header 'Authorization:''${AUTH_HEADER}'
          '')
      );
    in
    {
      programs.claude-code = {
        extraEnv = cfg.mcpEnv;
        extraPackages = mcpLaunchers;
        extraGitIgnores = [
          "credentials.json"
          "security_warnings_*.json"
        ];
        extraShellAliases = templateAliases;
      };
    };
}
