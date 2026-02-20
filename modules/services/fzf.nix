{ delib, ... }:
delib.module {
  name = "programs.fzf";

  home.always =
    { nixos, ... }:
    let
      currentShell = nixos.constants.shell or "zsh";
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
