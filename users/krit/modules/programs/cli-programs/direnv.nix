{ delib, config, ... }:
delib.module {
  name = "krit.programs.direnv";
  options.krit.programs.direnv = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          use_dev_env() {
            use flake /home/krit/nixOS/users/krit/dev-environments/language-specific/$1
          }
          use_combined_env() {
            use flake /home/krit/nixOS/users/krit/dev-environments/language-combined/$1
          }
        '';
      };
    };
}
