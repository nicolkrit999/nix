{ delib, moduleSystem, lib, pkgs, ... }:
let
  sharedIfEnabled = {
    environment.systemPackages = [ pkgs.nix-sweep ];
  };
in
delib.module {
  name = "nix-sweeps";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      gcd = noDefault (strOption null);
      gcn = noDefault (strOption null);
    };

  myconfig.always =
    { myconfig, ... }:
    {
      nix-sweeps = {
        gcd = lib.mkDefault myconfig.nh.gcd;
        gcn = lib.mkDefault myconfig.nh.gcn;
      };
    };

  nixos.ifEnabled = sharedIfEnabled;

  darwin.ifEnabled = sharedIfEnabled;

  home.ifEnabled =
    { cfg, ... }:
    {
      home.packages = lib.optionals (moduleSystem == "home") [ pkgs.nix-sweep ];

      xdg.configFile."nix-sweep/presets.toml".text = ''
        [default]
        keep-min = ${cfg.gcn}
        remove-older = "${cfg.gcd}"
        interactive = false
        gc = true

        [ask]
        keep-min = ${cfg.gcn}
        remove-older = "${cfg.gcd}"
        interactive = true
        gc = true
      '';
    };
}
