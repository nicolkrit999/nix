{ lib, vars, ... }:
{
  programs.git = {
    enable = true;

    userName = lib.mkIf (vars ? gitUserName) vars.gitUserName;
    userEmail = lib.mkIf (vars ? gitUserEmail) vars.gitUserEmail;

    lfs.enable = true;

    ignores = [
      ".direnv/"
      ".venv/"
      "result"
      "*.swp"
      ".DS_Store"
    ]
    ++ (vars.customGitIgnores or [ ]);

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
