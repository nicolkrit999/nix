{ lib, vars, ... }:
{
  programs.git = {
    enable = true;

    settings.user.name = lib.mkIf (vars ? gitUserName) vars.gitUserName;
    settings.user.email = lib.mkIf (vars ? gitUserEmail) vars.gitUserEmail;

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
