{ delib, ... }:
delib.module {
  name = "krit.programs.zen-browser";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.programs.zen.browser.enable = true;
}
