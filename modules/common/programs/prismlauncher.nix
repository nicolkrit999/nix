{ delib, pkgs, ... }:
delib.module {
  name = "programs.prismlauncher";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = [ pkgs.prismlauncher ];
  };
}
