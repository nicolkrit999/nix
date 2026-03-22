{ delib, moduleSystem, ... }:
delib.module {
  name = "krit.programs.direnv";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    let
      isDarwin = moduleSystem == "darwin";
      # Use appropriate paths for each platform
      devEnvBase =
        if isDarwin
        then "/Users/krit/nixOS/users/krit/dev-environments"
        else "/home/krit/nixOS/users/krit/dev-environments";
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
