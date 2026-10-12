{ delib, inputs, pkgs, lib, ... }:
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
        if [ -d "$HOME/${myconfig.constants.flakeDir}/.git" ]; then
          run ${pkgs.git}/bin/git -C "$HOME/${myconfig.constants.flakeDir}" config core.hooksPath .githooks
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
            name = lib.mkIf (myconfig.constants.gitUserName != "") myconfig.constants.gitUserName;
            email = lib.mkIf (myconfig.constants.gitUserEmail != "") myconfig.constants.gitUserEmail;
          };
          init.defaultBranch = "main";
          pull.ff = "only";
        };

        # GitHub Desktop needs the PATH git-lfs; HM's store-path default breaks it (8d8b312f)
        iniContent.filter.lfs = {
          clean = lib.mkForce "git-lfs clean -- %f";
          smudge = lib.mkForce "git-lfs smudge -- %f";
          process = lib.mkForce "git-lfs filter-process";
          required = lib.mkForce true;
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
