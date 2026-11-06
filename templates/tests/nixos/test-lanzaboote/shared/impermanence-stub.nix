{ delib, ... }:
delib.module {
  name = "services.impermanence";
  options = delib.singleEnableOption false;
}
