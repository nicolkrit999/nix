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
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
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
