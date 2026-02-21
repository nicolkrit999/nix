{ delib, ... }:
delib.module {
  # Disabling this module disable some aliases inside the shells .nix files
  name = "programs.fzf";
  options.programs.fzf = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
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
