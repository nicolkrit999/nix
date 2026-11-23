{ delib, pkgs, ... }:
let
  src = pkgs.fetchFromGitHub {
    owner = "tmck-code";
    repo = "yet-another-statusline";
    tag = "v0.4.8";
    hash = "sha256-VScEnzn+m31GYD+m6RpHDG5sjdhBY5jXSdfptOC2Fz0=";
  };

  python = pkgs.python3;

  yas-statusline = pkgs.writeShellApplication {
    name = "yas-statusline";
    runtimeInputs = [ pkgs.git ];
    text = ''
      exec ${python}/bin/python3 ${src}/claude/statusline_command.py "$@"
    '';
  };

  yas-prompt-hook = pkgs.writeShellApplication {
    name = "yas-prompt-hook";
    text = ''
      exec ${python}/bin/python3 ${src}/hooks/yas-prompt-hook.py "$@"
    '';
  };
in
delib.module {
  name = "programs.yas";

  home.always = {
    home.packages = [ yas-statusline yas-prompt-hook ];
  };
}
