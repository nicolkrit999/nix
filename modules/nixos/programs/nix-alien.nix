{ delib, inputs, lib, pkgs, ... }:
delib.module {
  name = "programs.nix-alien";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.nix-ld.enable = lib.mkForce true;

    environment.systemPackages = [
      inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
    ];
  };
}
