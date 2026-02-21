{ delib, lib, ... }:
delib.module {
  name = "programs.git";
  options.programs.git = with delib; {
    enable = boolOption true;
    customGitIgnores = listOfOption str [ ]; # 🌟 Moved here
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
        ++ cfg.customGitIgnores; # 🌟 Read from cfg

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
