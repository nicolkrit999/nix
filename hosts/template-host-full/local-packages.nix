{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "full-host.services.local-packages";
  options.full-host.services.local-packages.enable = delib.boolOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in

    {
      users.users.${myconfig.constants.user}.packages =
        (with pkgs; [

        ])

        ++ (with pkgs-unstable; [
        ]);
    };
}
