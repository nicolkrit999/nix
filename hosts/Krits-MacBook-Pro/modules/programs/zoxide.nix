{ delib, ... }:
delib.module {
  name = "programs.zoxide";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    {
      programs.zoxide = {
        enable = true;
        enableZshIntegration = (myconfig.constants.shell or "zsh") == "zsh";
        enableFishIntegration = (myconfig.constants.shell or "zsh") == "fish";
        enableBashIntegration = (myconfig.constants.shell or "zsh") == "bash";
      };
    };
}
