{ delib, inputs, pkgs, lib, ... }:
delib.module {
  name = "programs.claude-code";

  options = with delib; moduleOptions {
    enable = boolOption false;

    mcpSecrets = listOfOption
      (submodule {
        options = {
          sopsSecret = strOption "";
          envVar = strOption "";
        };
      })
      [];

    mcpEnv = attrsOption {};
  };

  home.ifEnabled = {
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
  };

  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
  };

  nixos.ifEnabled = { cfg, ... }:
    let
      envExports = lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (name: value: "export ${name}=${lib.escapeShellArg value}")
          cfg.mcpEnv
      );

      secretExports = lib.concatStringsSep "\n" (
        map (s: ''
          if [ -f "/run/secrets/${s.sopsSecret}" ]; then
            export ${s.envVar}="$(cat "/run/secrets/${s.sopsSecret}")"
          fi
        '') cfg.mcpSecrets
      );
    in
    {
      services.claude-cowork.enable = true;
      services.claude-cowork.package = inputs.claude-cowork-service.packages.${pkgs.stdenv.hostPlatform.system}.claude-cowork-service;
      nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

      environment.systemPackages = [
        pkgs.claude-code
        pkgs.python313Packages.litellm

        (pkgs.writeShellScriptBin "cai" ''
          ${envExports}
          ${secretExports}
          exec ${pkgs.claude-code}/bin/claude "$@"
        '')
      ];

      environment.shellAliases = {
        caiw = "cai --worktree";
        caitempplugins = "npx claude-code-templates@latest --plugins";
        caitemphealt = "npx claude-code-templates@latest --health-check";
        caitempchat = "npx claude-code-templates@latest --chats";
        caitempanalytics = "npx claude-code-templates@latest --analytics";
      };
    };
}
