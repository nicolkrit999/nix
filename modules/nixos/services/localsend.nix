{ delib, ... }:
delib.module {
  name = "services.localsend";
  options = delib.singleEnableOption false;

  nixos.ifEnabled.programs.localsend.enable = true;
}
