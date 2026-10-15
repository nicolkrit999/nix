{ delib, moduleSystem, ... }:
delib.module {
  name = "krit.programs.direnv";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    let
      homeDir = "${if moduleSystem == "darwin" then "/Users" else "/home"}/${myconfig.constants.user}";
      devEnvBase = "${homeDir}/${myconfig.constants.flakeDir}/templates/krit/dev-environments";
    in
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          use_dev_env() {
            use flake ${devEnvBase}/language-specific/$1
          }
          use_combined_env() {
            use flake ${devEnvBase}/language-combined/$1
          }
        '';
      };
    };
}
