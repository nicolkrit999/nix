{ delib
, inputs
, pkgs
, lib
, ...
}:
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
      home.packages = [ pkgs.gh ] ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.github-desktop;

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
          pull.rebase = true;
          rebase = {
            autoStash = true;
            autoSquash = true;
            updateRefs = true;
          };
          fetch = {
            prune = true;
            pruneTags = true;
          };
          push.autoSetupRemote = true;
          merge.conflictStyle = "zdiff3";
          rerere.enabled = true;
          diff = {
            algorithm = "histogram";
            colorMoved = "default";
          };
          help.autocorrect = "prompt";
          status = {
            short = true;
            branch = true;
          };
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
          detect-dark-light = "auto";
          side-by-side = true;
          line-numbers = true;
          hyperlinks = true;
          file-decoration-style = "blue box";
        };
      };
    };
}
