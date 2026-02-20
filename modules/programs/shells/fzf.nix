{ delib, ... }:
delib.module {
  name = "programs.fzf";

  home.always =
    {
      constants,
      ...
    }:
    let
      currentShell = constants.shell or "zsh";
    in
    {
      programs.fzf = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";
      };
    };
}
