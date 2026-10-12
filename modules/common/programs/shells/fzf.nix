{ delib, ... }:
delib.module {
  # Disabling this breaks fzf-prev/fzf-editor and drops fish's ctrl-g fzf-cd-widget bind
  name = "programs.fzf";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      currentShell = myconfig.constants.shell;
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
