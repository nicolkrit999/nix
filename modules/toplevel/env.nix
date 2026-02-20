{ delib, ... }:
delib.module {
  name = "env";

  nixos.always =
    { constants, ... }:

    let

      safeBrowser = constants.browser or "firefox";
      safeTerm = constants.term or "alacritty";
      safeEditor = constants.editor or "vscode";

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
