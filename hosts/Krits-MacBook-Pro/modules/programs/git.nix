{ delib, ... }:
delib.module {
  name = "programs.git";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    {
      programs.git = {
        enable = true;
        settings.user.name = myconfig.constants.gitUserName or "";
        settings.user.email = myconfig.constants.gitUserEmail or "";

        lfs.enable = true;

        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
          "*.jsonl"
          ".claude.json"
          ".claude.json.backup.*"
          ".credentials.json"
          "credentials.json"
          "security_warnings_*.json"
          "worktrees/"
          "**/.claude/*"
          "!**/.claude/agents/"
          "!**/.claude/keybindings.json"
          "!**/.claude/skills/"
          "!**/.claude/settings.json"
          "!**/.claude/statusline-commands.sh"
        ];

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
