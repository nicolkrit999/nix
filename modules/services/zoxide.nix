{ delib, ... }:
delib.module {
  name = "programs.zoxide";
  options.programs.zoxide = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { nixos, ... }:
    let
      currentShell = nixos.constants.shell or "zsh";
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
