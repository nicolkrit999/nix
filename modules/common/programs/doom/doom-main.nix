{ delib
, pkgs
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "programs.doom";

  options = delib.singleEnableOption false;

  home.always.imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

  home.ifEnabled.programs.doom-emacs = {
    enable = true;
    doomDir = ./doomdir;
    emacs =
      if moduleSystem == "darwin"
      then pkgs.emacs
      else pkgs.emacs-pgtk;
    provideEmacs = true;
    experimentalFetchTree = true;
  };
}
