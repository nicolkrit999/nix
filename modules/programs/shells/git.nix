{ delib, lib, ... }:
delib.module {
  name = "programs.git";
  # 🌟 Enabled by default!
  options.programs.git = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    {
      constants,
      ...
    }:
    {
      programs.git = {
        enable = true;

        settings.user.name = lib.mkIf (constants.constants ? gitUserName) constants.gitUserName;
        settings.user.email = lib.mkIf (constants.constants ? gitUserEmail) constants.gitUserEmail;

        lfs.enable = true;

        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
        ]
        ++ (constants.customGitIgnores or [ ]);

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
