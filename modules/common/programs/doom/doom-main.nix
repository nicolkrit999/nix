{ delib
, pkgs
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "programs.doom";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];
  };

  home.ifEnabled = { myconfig, ... }:
    let
      homePrefix = if moduleSystem == "darwin" then "/Users" else "/home";
      user = myconfig.constants.user;
    in
    {
      programs.doom-emacs = {
        enable = true;
        doomDir = ./doomdir;
        doomLocalDir = "${homePrefix}/${user}/.local/share/nix-doom";
        emacs =
          if moduleSystem == "darwin"
          then pkgs.emacs
          else pkgs.emacs-pgtk;
        provideEmacs = true;
        experimentalFetchTree = true;
      };
    };
}
