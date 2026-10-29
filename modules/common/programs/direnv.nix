{ delib, ... }:
delib.module {
  name = "programs.direnv";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
