{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.claude-code";
  options = delib.singleEnableOption false;

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
      "!**/.claude/skills/"
      "!**/.claude/settings.json"
      "!**/.claude/statusline-commands.sh"
    ];
  };

  nixos.always = {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];
  };

  nixos.ifEnabled = {
    services.claude-cowork.enable = true;
    services.claude-cowork.package = inputs.claude-cowork-service.packages.${pkgs.stdenv.hostPlatform.system}.claude-cowork-service; # Temporary to fix evaluation warning about "'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'"
    nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

    environment.systemPackages = [
      pkgs.claude-code

      (pkgs.writeShellScriptBin "cai" ''
        if [ -f /run/secrets/openrouter_api_claude_code ]; then
          export OPENROUTER_API_KEY=$(cat /run/secrets/openrouter_api_claude_code)
        fi
        exec ${pkgs.claude-code}/bin/claude "$@"
      '')
    ];

    environment.shellAliases = {
      caiw = "claude --worktree";
      caitempplugins = "npx claude-code-templates@latest --plugins";
      caitemphealt = "npx claude-code-templates@latest --health-check";
      caitempchat = "npx claude-code-templates@latest --chats";
      caitempanalytics = "npx claude-code-templates@latest --analytics";
    };
  };
}
