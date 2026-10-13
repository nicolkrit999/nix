{ delib, ... }:
delib.module {
  name = "stylix";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    targets = delib.attrsOption { };
  };
}
