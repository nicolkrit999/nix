{ delib, ... }:
delib.module {
  name = "krit.programs.discord";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.programs.discord.enable = true;
}
