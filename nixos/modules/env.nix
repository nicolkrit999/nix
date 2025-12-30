{
  term,
  editor,
  browser,
  ...
}:

let
  # Translation layer for editor commands with necessary flags
  # It may be necessary to add more editors and their flags here
  editorFlags = {
    "code" = "code --wait";
    "vscode" = "code --wait";
    "kate" = "kate --block";
    "gedit" = "gedit --wait";
    "subl" = "subl --wait";
    "nano" = "nano";
    "nvim" = "nvim";
    "vim" = "vim";
  };

  # Select the correct command, or default to the name itself if unknown
  finalEditor = editorFlags.${editor} or editor;
in
{
  environment.sessionVariables = {
    BROWSER = browser;

    TERMINAL = term;

    EDITOR = finalEditor;

    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [
      "$HOME/.local/bin"
    ];
  };
}
