{ delib, lib, moduleSystem, ... }:
let
  editorFlags = {
    "code" = "code --wait";
    "gedit" = "gedit --wait";
    "kate" = "kate --block";
    "nano" = "nano";
    "neovim" = "nvim";
    "nvim" = "nvim";
    "subl" = "subl --wait";
    "vim" = "vim";
    "vscode" = "code --wait";
  };

  sessionVars = myconfig:
    let
      editor = myconfig.constants.editor;
    in
    {
      EDITOR = editorFlags.${editor} or editor;
      XDG_BIN_HOME = "$HOME/.local/bin";
    }
    // lib.optionalAttrs (!myconfig.host.isServer) {
      BROWSER = myconfig.constants.browser;
      TERMINAL = myconfig.constants.terminal.name;
    };
in
delib.module {
  name = "env";

  nixos.always =
    { myconfig, ... }:
    {
      environment.localBinInPath = true;
      environment.sessionVariables = sessionVars myconfig;
    };

  home.always =
    { myconfig, ... }:
    lib.optionalAttrs (moduleSystem == "home") {
      home.sessionVariables = sessionVars myconfig;
    };
}
