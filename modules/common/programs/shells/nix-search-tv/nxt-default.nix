{ delib, ... }:
delib.module {
  name = "programs.fzf.nix-search-tv";
  options = delib.singleEnableOption false;
}
