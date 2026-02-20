{ delib, ... }:
delib.module {
  name = "system.env";

  myconfig.always =
    { myconfig, ... }:

    let

      safeBrowser = myconfig.constants.browser or "firefox";
      safeTerm = myconfig.constants.term or "alacritty";
      safeEditor = myconfig.constants.editor or "vscode";

      # Translation layer for editor commands with necessary flags
      # It may be necessary to add more editors and their flags here
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

      # Select the correct command, or default to the name itself if unknown
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
