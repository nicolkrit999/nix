{ delib, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  # homeModules.nix-index is imported in nix-nixos.nix and nix-darwin.nix via home.always
  home.ifEnabled = {
    programs.nix-index-database.comma.enable = true;
  };
}
