{ delib, inputs, pkgs, lib, ... }:
let
  shellAliases = {
    caitempplugins = "npx claude-code-templates@latest --plugins";
    caitemphealt = "npx claude-code-templates@latest --health-check";
    caitempchat = "npx claude-code-templates@latest --chats";
    caitempanalytics = "npx claude-code-templates@latest --analytics";
    cai-openrouter-geminipro = "cai-openrouter --model google/gemini-3.1-pro-preview[1m]";
    cai-openrouter-geminiflash = "cai-openrouter --model google/gemini-3.1-flash-lite-preview[1m]";
    cai-openrouter-gptpro = "cai-openrouter --model openai/gpt-5.4-pro[1m]";
    cai-openrouter-gptmini = "cai-openrouter --model openai/gpt-5.4-mini[1m]"; # In reality support 400k but it does not recognize "k" nor "m" with decimals
    cai-openrouter-opus = "cai-openrouter --model anthropic/claude-opus-4.6[1m]";
    cai-openrouter-sonnet = "cai-openrouter --model anthropic/claude-sonnet-4.6[1m]";
    cai-openrouter-maverick = "cai-openrouter --model meta-llama/llama-4-maverick[1m]";
    cai-openrouter-scout = "cai-openrouter --model meta-llama/llama-4-scout[1m]";
    cai-openrouter-glmturbo = "cai-openrouter --model z-ai/glm-5-turbo";
    cai-openrouter-grokbeta = "cai-openrouter --model x-ai/grok-4.20-beta[1m]";
    cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not alllow anything more than 1m
    cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
    cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
    cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
    cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
    cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
    cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
  };
in
delib.module {
  name = "programs.claude-code";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
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
      default = [ ];
      description = "List of MCP secrets to provision via sops-nix.";
    };
    mcpEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Static environment variables for MCP servers.";
    };
  };

  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
  };

  nixos.ifEnabled = { ... }: {
    environment.systemPackages = [ pkgs.claude-code ];
  };

  home.ifEnabled = { myconfig, ... }: {
    programs.git.ignores = [
      # Claude code
      "*.jsonl"
      ".claude.json"
      ".claude.json.backup.*"
      ".credentials.json"
      "credentials.json"
      "security_warnings_*.json"
      "**/.claude/*"
      "!**/.claude/agents/"
      "!**/.claude/keybindings.json"
      "!**/.claude/skills/"
      "!**/.claude/settings.json"
      "!**/.claude/statusline-commands.sh"
    ];

    programs.fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") shellAliases;
    programs.zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") shellAliases;
    programs.bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") shellAliases;
  };
}
