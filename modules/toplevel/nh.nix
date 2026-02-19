{ vars, ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    # Keep generations from the last 30 days and at least 20 generations
    clean.extraArgs = "--keep-since 30d --keep 20";
    flake = "/home/${vars.user}/nixOS";
  };
}
