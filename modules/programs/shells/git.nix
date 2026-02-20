{ delib, lib, ... }:
delib.module {
  name = "programs.git";
  options.programs.git.enable = delib.boolOption true;

  # 🏠 HOME MANAGER HOOK ONLY
  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      programs.git = {
        enable = true;

        # 🌟 THE FIX: Correct Home Manager identity attributes
        userName = myconfig.constants.gitUserName;
        userEmail = myconfig.constants.gitUserEmail;
        lfs.enable = true;

        # 🌟 THE FIX: Correct nesting for Delta inside Git
        delta = {
          enable = true;
          options = {
            navigate = true;
            light = false;
            side-by-side = true;
          };
        };

        # 🌟 THE FIX: 'ignores' belongs here in Home Manager
        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
        ]
        ++ (myconfig.constants.customGitIgnores or [ ]);

        # 🌟 THE FIX: Use 'extraConfig' for branch/rebase settings
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };
    };
}
