{ delib, pkgs, ... }:
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
        flake = "/home/${myconfig.constants.user}/nix";
      };
    };

  darwin.ifEnabled =
    { ... }:
    {
      environment.systemPackages = with pkgs; [
        nh
      ];
    };
}
