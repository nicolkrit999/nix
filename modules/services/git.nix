{ delib, ... }:
delib.module {
  name = "programs.git";
  # 🌟 Enabled by default!
  options.programs.git = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    { lib, nixos, ... }:
    {
      programs.git = {
        enable = true;

        settings.user.name = lib.mkIf (nixos.constants ? gitUserName) nixos.constants.gitUserName;
        settings.user.email = lib.mkIf (nixos.constants ? gitUserEmail) nixos.constants.gitUserEmail;

        lfs.enable = true;

        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
        ]
        ++ (nixos.constants.customGitIgnores or [ ]);

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
