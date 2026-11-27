{ delib, ... }:
delib.module {
  name = "krit.services.laptop.flatpak";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.flatpak.packages = [
      "dev.mariinkys.StarryDex" # Pokedex
    ];
  };
}
