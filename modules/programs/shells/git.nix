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
        lfs.enable = true;

        # 'ignores' remains a top-level attribute in Home Manager
        ignores = [
          ".direnv/"
          ".venv/"
          "result"
          "*.swp"
          ".DS_Store"
        ]
        ++ (myconfig.constants.customGitIgnores or [ ]);

        # 🌟 THE FIX: Consolidated userName, userEmail, and extraConfig into 'settings'
        settings = {
          user = {
            name = myconfig.constants.gitUserName;
            email = myconfig.constants.gitUserEmail;
          };
          init.defaultBranch = "main";
          pull.rebase = true;
        };
      };

      # 🌟 THE FIX: Delta is now its own top-level program configuration
      programs.delta = {
        enable = true;
        enableGitIntegration = true; # Explicitly set to silence the warning
        options = {
          navigate = true;
          light = false;
          side-by-side = true;
        };
      };
    };
}
