{ delib, ... }:
delib.module {
  name = "programs.ranger";
  options = delib.singleEnableOption false;

  home.ifEnabled.programs.ranger.enable = true;
}
