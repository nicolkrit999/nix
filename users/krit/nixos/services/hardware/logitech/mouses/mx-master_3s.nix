{ delib, ... }:
delib.module {
  name = "krit.services.logitech.mouses.mx-master-3s";
  options = delib.singleEnableOption false;
  # Config is handled by logitech-main.nix which reads this enable flag
}
