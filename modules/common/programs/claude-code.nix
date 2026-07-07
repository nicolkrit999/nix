{ delib, inputs, pkgs, lib, moduleSystem, config, ... }:
let
  shellAliases = {
    caitempplugins = "npx claude-code-templates@latest --plugins";
    caitemphealt = "npx claude-code-templates@latest --health-check";
    caitempchat = "npx claude-code-templates@latest --chats";
    caitempanalytics = "npx claude-code-templates@latest --analytics";
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
    cai-openrouter-grokmulti = "cai-openrouter --model x-ai/grok-4.20-multi-agent-beta[1m]"; # In reality support 2M but it does not alllow anything more than 1m
    cai-openrouter-free-step = "cai-openrouter --model stepfun/step-3.5-flash:free";
    cai-openrouter-free-hunter = "cai-openrouter --model openrouter/hunter-alpha[1m]";
    cai-openrouter-mistralsmall = "cai-openrouter --model mistralai/mistral-small-2603";
    cai-openrouter-kimi = "cai-openrouter --model moonshotai/kimi-k2.5";
    cai-openrouter-qwen = "cai-openrouter --model qwen/qwen3.5-397b-a17b";
    cai-openrouter-minimax = "cai-openrouter --model minimax/minimax-m2.5";
  };
  claudeCodePackages = [
    pkgs.claude-code
    pkgs.nodejs_latest
    pkgs.bun
    pkgs.rtk
  ];
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

  # ===========================================================================
  # DARWIN CONFIGURATION
  # ===========================================================================
  darwin.always =
    { ... }:
    {
      nixpkgs.overlays = [
        inputs.claude-code.overlays.default
      ];
    };

  darwin.ifEnabled =
    { ... }:
    {
      environment.systemPackages = claudeCodePackages;
    };

  # ===========================================================================
  # NIXOS CONFIGURATION
  # ===========================================================================
  nixos.always = { ... }: {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
    nixpkgs.overlays = [
      inputs.claude-code.overlays.default
    ];
  };

  nixos.ifEnabled = { ... }: {
    environment.systemPackages = claudeCodePackages;
  };

  home.ifEnabled = { myconfig, ... }:
    let
      mcpSecrets = myconfig.programs.claude-code.mcpSecrets;
      mcpEnv = myconfig.programs.claude-code.mcpEnv;

      # ---------------------------------------------------------------------
      # Home-standalone (moduleSystem == "home", e.g. Nicol-NAS) MCP secret/env
      # consumer.
      #
      # On NixOS/Darwin the actual consumer of an MCP secret's *value* is
      # users/krit/common/programs/claude-code-wrappers.nix's cai-openrouter
      # script, which hardcodes `cat /run/secrets/openrouter_api_claude_code`
      # and exports ANTHROPIC_AUTH_TOKEN from it - a root-owned system-sops
      # path. That mechanism is single-purpose (only ever wired the one
      # OPENROUTER secret) and structurally can't extend to the rest of
      # mcpSecrets/mcpEnv: /run/secrets doesn't exist on an unprivileged
      # home-manager-only build, and claude-code-wrappers.nix's `cai` family
      # also pulls in the claude.ai-connector policy-rewrite machinery, which
      # has no reason to run on a headless NAS.
      #
      # So for home builds we wrap the `claude` binary itself: a
      # writeShellScriptBin "claude" that, at RUNTIME (never at build time -
      # no secret value is ever embedded in the nix store, only the sops-nix
      # runtime *path*), exports each mcpSecrets entry by `cat`-ing
      # config.sops.secrets.<name>.path (sops-nix's home-manager module
      # resolves this to the stable ~/.config/sops-nix/secrets/<name> symlink
      # - see users/krit/common/toplevel/sops-secrets.nix's
      # mkClaudeMcpSecretsHome, which declares the very same mcpSecrets list
      # as sops.secrets so these paths exist), plus each static mcpEnv var,
      # then execs the real claude-code binary. This wrapper *replaces*
      # pkgs.claude-code in home.packages for home builds only (rather than
      # sitting alongside it) so there is no bin/claude collision in the
      # home-manager profile.
      mcpSecretExports = map
        (s: ''export ${s.envVar}="$(cat ${lib.escapeShellArg config.sops.secrets.${s.sopsSecret}.path})"'')
        mcpSecrets;
      mcpStaticExports = lib.mapAttrsToList
        (name: value: "export ${name}=${lib.escapeShellArg value}")
        mcpEnv;

      claudeHomeWrapper = pkgs.writeShellScriptBin "claude" ''
        ${lib.concatStringsSep "\n" (mcpSecretExports ++ mcpStaticExports)}
        exec ${pkgs.claude-code}/bin/claude "$@"
      '';

      homeClaudeCodePackages = [
        claudeHomeWrapper
        pkgs.nodejs_latest
        pkgs.bun
        pkgs.rtk
      ];
    in
    {
      home.sessionVariables.CLAUDE_BINARY = "${pkgs.claude-code}/bin/.claude-unwrapped";
      programs.git.ignores = [
        # Claude code
        "credentials.json"
        "security_warnings_*.json"
      ];

      programs.fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") shellAliases;
      programs.zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") shellAliases;
      programs.bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") shellAliases;

      # On integrated NixOS/Darwin builds, claudeCodePackages are installed via
      # environment.systemPackages in nixos.ifEnabled/darwin.ifEnabled above -
      # installing them again here would double-install, and their MCP-secret
      # consumption path is unchanged (claude-code-wrappers.nix, /run/secrets).
      # On a standalone home-manager build (moduleSystem == "home", e.g.
      # Nicol-NAS) there is no system-level package set to fall back on, so
      # home.packages is the only place these get installed - and the wrapped
      # `claude` above is what actually wires mcpSecrets/mcpEnv into the
      # process environment there. Plain if/else (not lib.mkIf) per the
      # standing pattern for moduleSystem guards - see ssh-config.nix /
      # git-ssh-signing.nix.
      home.packages = if moduleSystem == "home" then homeClaudeCodePackages else [ ];
    };
}
