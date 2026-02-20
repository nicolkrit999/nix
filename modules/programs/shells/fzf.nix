{ delib, ... }:
delib.module {
  name = "programs.fzf";

  home.always =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      currentShell = myconfig.constants.shell or "zsh";
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
