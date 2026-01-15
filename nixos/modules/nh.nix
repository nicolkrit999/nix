{ vars, ... }:
{
  programs.nh = {
    enable = true;
    flake = "/home/${vars.user}/nixOS";
  };
}
