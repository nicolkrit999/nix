{ delib, inputs, pkgs, ... }:
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
      home.activation.setupNixRepoHooks = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "$HOME/nix/.git" ]; then
          $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$HOME/nix" config core.hooksPath .githooks
        fi
      '';

      programs.git = {
        enable = true;
        lfs.enable = true;

        ignores = [
          ".direnv/"
          ".venv/"
          ".env"
          ".envrc"
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
          pull.ff = "only";
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
