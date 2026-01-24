{ vars, ... }:
{
  programs.git = {
    enable = true;
    settings.user.name = vars.gitUserName; # Your public display name on commits
    settings.user.email = vars.gitUserEmail; # Email linked to GitHub/GitLab
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
