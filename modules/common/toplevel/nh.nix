{ delib, pkgs, ... }:
delib.module {
  name = "nh";
  options = delib.singleEnableOption true;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 30d --keep 10";
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
