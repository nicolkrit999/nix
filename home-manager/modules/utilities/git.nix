{ vars, ... }:
{
  programs.git = {
    enable = true;

    settings.user.name = vars.gitUserName; # Your public display name on commits
    settings.user.email = vars.gitUserEmail; # Email linked to GitHub/GitLab

    lfs.enable = true;

    ignores = [
      ".direnv/"
      ".envrc"
      ".venv/"
      "result"
      "*.swp"
      ".DS_Store"
    ];

    # Optional: Enable Git credential helper if using HTTPS
    # extraConfig = { credential.helper = "store"; };
  };
}
