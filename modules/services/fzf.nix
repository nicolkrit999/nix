{
  vars,
  ...
}:
let
  currentShell = vars.shell or "zsh";
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = currentShell == "zsh";
    enableFishIntegration = currentShell == "fish";
    enableBashIntegration = currentShell == "bash";
  };
}
