{ delib, pkgs, ... }:
let
  src = pkgs.fetchFromGitHub {
    owner = "tmck-code";
    repo = "yet-another-statusline";
    rev = "ff36eed827171d2576c510de28304f897f22def2";
    hash = "sha256-OkSCCXbLnQF6x9EfPaptfb1bCtWem3H5Mpn1wgxRFUc=";
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
