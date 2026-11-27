{ delib, ... }:
delib.module {
  name = "krit.services.desktop.flatpak";
  options = delib.singleEnableOption false;
  nixos.ifEnabled = {
    services.flatpak.packages = [
    ];
  };
}
