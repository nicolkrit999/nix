{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  # Deliberately unpinned `@latest`: a manual escape hatch, not a managed tool.
  templateAliases = {
    caitempplugins = "npx claude-code-templates@latest --plugins";
    caitemphealt = "npx claude-code-templates@latest --health-check";
    caitempchat = "npx claude-code-templates@latest --chats";
    caitempanalytics = "npx claude-code-templates@latest --analytics";
  };
  openrouterAliases = {
    cai-openrouter-geminipro = "cai-openrouter --model google/gemini-3.1-pro-preview[1m]";
    cai-openrouter-geminiflash = "cai-openrouter --model google/gemini-3.1-flash-lite-preview[1m]";
    cai-openrouter-gptpro = "cai-openrouter --model openai/gpt-5.5-pro[1m]";
    cai-openrouter-gptmini = "cai-openrouter --model openai/gpt-5.5-mini[1m]"; # In reality support 400k but it does not recognize "k" nor "m" with decimals
    cai-openrouter-opus = "cai-openrouter --model anthropic/claude-opus-4.7[1m]";
    cai-openrouter-sonnet = "cai-openrouter --model anthropic/claude-sonnet-4.7[1m]";
    cai-openrouter-maverick = "cai-openrouter --model meta-llama/llama-4-maverick[1m]";
    cai-openrouter-scout = "cai-openrouter --model meta-llama/llama-4-scout[1m]";
    cai-openrouter-glmturbo = "cai-openrouter --model z-ai/glm-5-turbo";
    cai-openrouter-grokbeta = "cai-openrouter --model x-ai/grok-4.20-beta[1m]";
    cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not allow anything more than 1m
    cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
    cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
    cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
    cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
    cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
    cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
  };
  overlays = [ inputs.claude-code.overlays.default ];
  claudeCodeTools = [
    pkgs.bun
    pkgs.gh
    pkgs.nodejs_latest
    pkgs.rtk
  ];
  sharedIfEnabled = {
    environment.systemPackages = [ pkgs.claude-code ] ++ claudeCodeTools;
  };
in
delib.module {
  name = "programs.claude-code";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    cowork = delib.boolOption false;
    mcpSecrets = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          sopsSecret = lib.mkOption {
            type = lib.types.str;
            description = "The sops secret name (key in sops.secrets).";
          };
          envVar = lib.mkOption {
            type = lib.types.str;
            description = "The environment variable name for this secret.";
          };
        };
      });
      # Default for every host that does not override it (Nicol-NAS does; the
      # Darwin sops declarations keep their own static list).
      default = [
        { sopsSecret = "openrouter_api_claude_code"; envVar = "OPENROUTER_API_KEY"; }
        { sopsSecret = "claude_mcp_actual_password"; envVar = "ACTUAL_PASSWORD"; }
        { sopsSecret = "claude_mcp_actual_sync_id"; envVar = "ACTUAL_SYNC_ID"; }
        { sopsSecret = "claude_mcp_actual_encryption_password"; envVar = "ACTUAL_BUDGET_ENCRYPTION_PASSWORD"; }
        { sopsSecret = "claude_mcp_context7_api_key"; envVar = "CONTEXT7_API_KEY"; }
        { sopsSecret = "claude_mcp_openai_api_key"; envVar = "OPENAI_API_KEY"; }
        { sopsSecret = "claude_mcp_milvus_token"; envVar = "MILVUS_TOKEN"; }
        { sopsSecret = "claude_mcp_github_token"; envVar = "GITHUB_TOKEN"; }
        { sopsSecret = "claude_mcp_portainer_token"; envVar = "PORTAINER_TOKEN"; }
        { sopsSecret = "claude_mcp_sparkyfitness_api_key"; envVar = "SPARKYFITNESS_API_KEY"; }
        { sopsSecret = "claude_mcp_vikunja_token"; envVar = "VIKUNJA_API_TOKEN"; }
        { sopsSecret = "claude_mcp_beszel_email"; envVar = "BESZEL_EMAIL"; }
        { sopsSecret = "claude_mcp_beszel_password"; envVar = "BESZEL_PASSWORD"; }
      ];
      description = "Names of the MCP secrets; the sops declarations are generated from this list elsewhere, MCP launchers read the secret files themselves.";
    };
    mcpEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      # Default unless a host overrides it; only the home-build wrapper exports it.
      default = {
        ACTUAL_SERVER_URL = "https://budget.nicolkrit.ch";
      };
      description = "Static environment variables exported by the home-build `claude` wrapper.";
    };
  };

  # ===========================================================================
  # DARWIN CONFIGURATION
  # ===========================================================================
  darwin.always.nixpkgs.overlays = overlays;

  darwin.ifEnabled = sharedIfEnabled;

  # ===========================================================================
  # NIXOS CONFIGURATION
  # ===========================================================================
  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
    nixpkgs.overlays = overlays;
  };

  nixos.ifEnabled = { cfg, ... }: sharedIfEnabled // {
    services.claude-cowork.enable = cfg.cowork;
  };

  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = overlays;
  };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      shellAliases = templateAliases
        // lib.optionalAttrs myconfig.krit.programs.claude-code-wrappers.enable openrouterAliases;

      mcpStaticExports = lib.mapAttrsToList
        (name: value: "export ${name}=${lib.escapeShellArg value}")
        cfg.mcpEnv;

      claudeHomeWrapper = pkgs.writeShellScriptBin "claude" ''
        ${lib.concatStringsSep "\n" mcpStaticExports}
        exec ${pkgs.claude-code}/bin/claude "$@"
      '';
    in
    {
      home.sessionVariables.CLAUDE_BINARY = "${pkgs.claude-code}/bin/.claude-unwrapped";

      programs = {
        git.ignores = [
          "credentials.json"
          "security_warnings_*.json"
        ];

        fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") shellAliases;
        zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") shellAliases;
        bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") shellAliases;
      };

      home.packages = lib.optionals (moduleSystem == "home") ([ claudeHomeWrapper ] ++ claudeCodeTools);
    };
}
