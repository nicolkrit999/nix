{ delib, lib, config, moduleSystem, ... }:
delib.module {
  name = "nh";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      gcd = strOption "30d";
      gcn = strOption "3";
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since ${cfg.gcd} --keep ${cfg.gcn}";
        flake = "/home/${myconfig.constants.user}/${myconfig.constants.flakeDir}";
      };
    };

  nixos.ifDisabled =
    { myconfig, ... }:
    {
      assertions = [
        {
          assertion = !myconfig.programs.shell-aliases.enable || myconfig.constants.nixImpure;
          message = ''
            myconfig.nh.enable is false, but the NixOS rebuild aliases from
            programs.shell-aliases (sw, gsw, upd, swboot, swtest, ...) run `nh os`
            while constants.nixImpure is false. Enable nh, set
            constants.nixImpure = true, or disable programs.shell-aliases.
          '';
        }
      ];
    };

  darwin.ifEnabled =
    { cfg, myconfig, ... }:
    {
      home-manager.users.${myconfig.constants.user}.programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = [ "--keep-since" cfg.gcd "--keep" cfg.gcn ];
        flake = "/Users/${myconfig.constants.user}/${myconfig.constants.flakeDir}";
      };
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    lib.optionalAttrs (moduleSystem == "home") {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = [ "--keep-since" cfg.gcd "--keep" cfg.gcn ];
        flake = "${config.home.homeDirectory}/${myconfig.constants.flakeDir}";
      };
    };

  darwin.ifDisabled =
    { myconfig, ... }:
    {
      assertions = [
        {
          assertion = !myconfig.programs.shell-aliases.enable || myconfig.constants.nixImpure;
          message = ''
            myconfig.nh.enable is false, but the Darwin rebuild aliases from
            programs.shell-aliases (sw, gsw, upd, swdry, ...) run `nh darwin`
            while constants.nixImpure is false. Enable nh, set
            constants.nixImpure = true, or disable programs.shell-aliases.
          '';
        }
      ];
    };
}
