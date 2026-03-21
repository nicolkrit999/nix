{ delib, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  # Use nix-index-database's wrapped comma (module imported in nix-darwin.nix)
  darwin.ifEnabled = {
    programs.nix-index-database.comma.enable = true;
  };
}
