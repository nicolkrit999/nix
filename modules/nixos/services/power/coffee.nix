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

  mkCoffee = name: extraInputs: pkgs.writeShellApplication {
    name = "coffee-${name}";
    runtimeInputs = extraInputs ++ [
      pkgs.systemd
      pkgs.util-linux
      pkgs.libnotify
      pkgs.procps
      pkgs.coreutils
      pkgs.gnugrep
    ];
    excludeShellChecks = [ "SC2329" ] ++ lib.optional (name == "toggle") "SC2034";
    text = builtins.readFile ./coffee/coffee-lib.sh + builtins.readFile ./coffee/coffee-${name}.sh;
  };

  coffeeOn = mkCoffee "on" [ ];
  coffeeOff = mkCoffee "off" [ ];
  coffeeStatus = mkCoffee "status" [ ];
  coffeeToggle = mkCoffee "toggle" [ coffeeOn coffeeOff ];
in
delib.module {
  name = "services.coffee";

  options = delib.moduleOptions {
    enable = delib.boolOption true;
    togglePackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = coffeeToggle;
      defaultText = lib.literalExpression "coffee-toggle";
      description = "The coffee-toggle script, for click actions (the waybar pill) that cannot rely on PATH.";
    };
  };

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
      home.packages = [ coffeeOn coffeeOff coffeeStatus coffeeToggle ];
    };
}
