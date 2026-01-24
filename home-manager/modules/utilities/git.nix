{ lib, vars, ... }: {
  programs.git = {
    enable = true;

    userName = vars.gitUserName or null;
    userEmail = vars.gitUserEmail or null;

    lfs.enable = true;

    ignores = [ ".direnv/" ".venv/" "result" "*.swp" ".DS_Store" ]
      ++ (vars.customGitIgnores or [ ]);

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
