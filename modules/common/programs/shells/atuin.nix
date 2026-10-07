{ delib, ... }:
delib.module {
  name = "programs.atuin";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      currentShell = myconfig.constants.shell or "zsh";
    in
    {
      programs.atuin = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";
      };
    };
}
