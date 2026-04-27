{ delib, ... }:
delib.module {
  name = "env";

  nixos.always =
    { myconfig, ... }:
    let
      safeBrowser = myconfig.constants.browser or "firefox";
      safeTerm = myconfig.constants.terminal or "alacritty";
      safeEditor = myconfig.constants.editor or "vscode";

      # Add more if needed
      editorFlags = {
        "code" = "code --wait";
        "vscode" = "code --wait";
        "kate" = "kate --block";
        "gedit" = "gedit --wait";
        "subl" = "subl --wait";
        "nano" = "nano";
        "neovim" = "nvim";
        "nvim" = "nvim";
        "vim" = "vim";
      };

      finalEditor = editorFlags.${safeEditor} or safeEditor;
    in
    {
      environment.localBinInPath = true;

      environment.sessionVariables = {
        BROWSER = safeBrowser;
        TERMINAL = safeTerm;
        EDITOR = finalEditor;
        XDG_BIN_HOME = "$HOME/.local/bin";
      };
    };
}
