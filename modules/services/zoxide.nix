{ pkgs, vars, ... }:
let
  currentShell = vars.shell or "zsh";
in
{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = currentShell == "zsh";
    enableFishIntegration = currentShell == "fish";
    enableBashIntegration = currentShell == "bash";
  };
}
