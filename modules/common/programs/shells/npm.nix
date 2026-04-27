{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.npm";
  options = delib.singleEnableOption false;

  home.ifEnabled = { ... }: {
    home.packages = [ pkgs.nodejs_latest ];

    home.file.".npmrc".text = ''
      prefix = ''${HOME}/.npm-global
    '';

    home.sessionPath = [ "$HOME/.npm-global/bin" ];
  };
}
