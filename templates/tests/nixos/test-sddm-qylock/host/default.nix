{ delib, ... }:
delib.host {
  name = "test-sddm-qylock";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ../shared/constants.nix;
    services.sddm-qylock.enable = true;
  };
}
