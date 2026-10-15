{ delib
, inputs
, ...
}:
let
  # Same name -> command map as modules/nixos/toplevel/env.nix (constants.editor accepts
  # package-style names such as "neovim"/"vscode", which are not command names).
  editorCommands = {
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
in
delib.module {
  name = "krit.home.base";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      editor = myconfig.constants.editor;
      editorCommand = editorCommands.${editor} or editor;
    in
    {
      home.stateVersion = "25.11";

      home.sessionVariables = {
        EDITOR = editorCommand;
        VISUAL = editorCommand;
      };

      home.activation = {
        createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/Pictures/wallpapers" "$HOME/momentary" "$HOME/.config/portainer-mcp" || true
        '';
      };
    };
}
