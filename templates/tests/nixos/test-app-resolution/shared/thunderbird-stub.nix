{ delib, ... }:
delib.module {
  name = "programs.thunderbird";
  options = delib.singleEnableOption false;
}
