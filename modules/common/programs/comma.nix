{ delib, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    programs.nix-index-database.comma.enable = true;
  };
}
