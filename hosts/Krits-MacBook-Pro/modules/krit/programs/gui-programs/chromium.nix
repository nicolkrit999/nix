{ delib, ... }:
delib.module {
  name = "krit.programs.chromium";

  options.krit.programs.chromium = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled = { ... }: { };
}
