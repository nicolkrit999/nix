{ delib, ... }:
delib.module {
  name = "programs.git";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      customGitIgnores = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      programs.git = {
        enable = true;
        lfs.enable = true;

        ignores = [
          # Virtual environments and direnv
          ".direnv/"
          ".venv/"

          # Nix build results
          "result"

          # Editor swap files and OS trash
          "*.swp"
          ".DS_Store"

          # Claude code
          "*.jsonl"
          ".claude.json"
          ".claude.json.backup.*"
          ".credentials.json"
          "credentials.json"
          "security_warnings_*.json"
          "**/.claude/*"
          "!**/.claude/agents/"
          "!**/.claude/plugins/"
          "**.claude/plugins/marketplaces/"
          "**.claude/plugins/install-counts-cache.json"
          "!**/.claude/skills/"
          "!**/.claude/settings.json"
          "!**/.claude/statusline-commands.sh"
        ]
        ++ cfg.customGitIgnores;

        settings = {
          user = {
            name = myconfig.constants.gitUserName;
            email = myconfig.constants.gitUserEmail;
          };
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true;
          light = false;
          side-by-side = true;
        };
      };
    };
}
