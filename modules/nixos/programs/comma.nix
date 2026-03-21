{ delib, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  # Use nix-index-database's wrapped comma (module imported in nix-nixos.nix)
  nixos.ifEnabled = {
    programs.nix-index-database.comma.enable = true;
  };
}
