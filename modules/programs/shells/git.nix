{ delib, lib, ... }:
delib.module {
  name = "programs.git";
  # 🌟 Enabled by default!
  options.programs.git = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    {
      programs.git = {
        enable = true;

        settings.user.name = lib.mkIf (
          myconfig.constants.constants ? gitUserName
        ) myconfig.constants.gitUserName;
        settings.user.email = lib.mkIf (
          myconfig.constants.constants ? gitUserEmail
        ) myconfig.constants.gitUserEmail;

        lfs.enable = true;

        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
        ]
        ++ (myconfig.constants.customGitIgnores or [ ]);

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
