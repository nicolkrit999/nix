{ delib, pkgs, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  # The nix-index-database overlay (applied in nix-nixos.nix and nix-darwin.nix) provides comma-with-db
  home.ifEnabled = {
    home.packages = [ pkgs.comma-with-db ];
  };
}
