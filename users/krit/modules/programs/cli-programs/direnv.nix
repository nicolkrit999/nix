{ delib, config, ... }:
delib.module {
  name = "krit-direnv";
  options.krit.programs.direnv.enable = delib.boolOption true;

  home.ifEnabled =
    { cfg, ... }:
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          use_dev_env() {
            use flake ${config.home.homeDirectory}/nixOS/common/krit/modules/system/dev-environments/language-specific/$1
          }
          use_combined_env() {
            use flake ${config.home.homeDirectory}/nixOS/common/krit/modules/system/dev-environments/language-combined/$1
          }
        '';
      };
    };
}
