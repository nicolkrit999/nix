{ delib
, pkgs
, lib
, ...
}:
let
  isWmEnabled = myconfig:
    (myconfig.programs.hyprland.enable or false)
    || (myconfig.programs.niri.enable or false)
    || (myconfig.programs.mango.enable or false);

  mkCoffee = name: pkgs.writeShellApplication {
    name = "coffee-${name}";
    runtimeInputs = [
      pkgs.systemd
      pkgs.util-linux
      pkgs.libnotify
      pkgs.procps
      pkgs.coreutils
      pkgs.gnugrep
    ];
    excludeShellChecks = [ "SC2329" ];
    text = builtins.readFile ./coffee/coffee-lib.sh + builtins.readFile ./coffee/coffee-${name}.sh;
  };
in
delib.module {
  name = "services.coffee";

  options = delib.singleEnableOption true;

  # coffee's weak sleep lock would otherwise also swallow the suspend/hibernate keys
  nixos.ifEnabled = { myconfig, ... }:
    lib.mkIf (isWmEnabled myconfig) {
      services.logind.settings.Login = {
        SuspendKeyIgnoreInhibited = "yes";
        HibernateKeyIgnoreInhibited = "yes";
      };
    };

  home.ifEnabled = { myconfig, ... }:
    lib.mkIf (isWmEnabled myconfig) {
      home.packages = map mkCoffee [ "on" "off" "status" ];
    };
}
