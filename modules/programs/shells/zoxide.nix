{ delib, ... }:
delib.module {
  name = "programs.zoxide";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "zsh";
    in
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";
      };
    };
}
