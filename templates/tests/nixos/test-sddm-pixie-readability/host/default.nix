{ delib, ... }:
delib.host {
  name = "test-sddm-pixie-readability";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ../shared/constants.nix;
    services.sddm-pixie.enable = true;
  };
}
