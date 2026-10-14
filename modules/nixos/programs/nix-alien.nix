{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.nix-alien";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.nix-ld.enable = true;

    environment.systemPackages = [
      inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
    ];
  };
}
