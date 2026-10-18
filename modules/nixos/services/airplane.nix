{ delib
, pkgs
, lib
, config
, ...
}:
let
  airplane = pkgs.writeShellApplication {
    name = "airplane";
    runtimeInputs = [
      pkgs.networkmanager
      pkgs.util-linux
      pkgs.libnotify
      pkgs.procps
      pkgs.coreutils
      pkgs.gnugrep
    ];
    excludeShellChecks = [ "SC2329" ];
    text = builtins.readFile ./airplane/airplane.sh;
  };
in
delib.module {
  name = "services.airplane";

  options = delib.moduleOptions {
    enable = delib.boolOption (config.networking.networkmanager.enable or false);
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = airplane;
      defaultText = lib.literalExpression "airplane";
      description = "The airplane script, for click actions (the waybar pill) that cannot rely on PATH.";
    };
  };

  nixos.ifEnabled = {
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "myconfig.services.airplane needs networking.networkmanager.enable; set myconfig.services.airplane.enable = false on this host.";
      }
    ];
  };

  home.ifEnabled = {
    home.packages = [ airplane ];
    home.shellAliases = {
      airplane-on = "airplane full";
      airplane-off = "airplane off";
    };
  };
}
