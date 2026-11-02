{ delib, ... }:
delib.module {
  name = "krit.programs.zen-browser";
  options = with delib; moduleOptions {
    enable = boolOption false;
    # true: keep only the University space/container and the pins that belong to it
    universityOnly = boolOption false;
  };

  myconfig.ifEnabled.programs.zen.browser.enable = true;
}
