{ delib, ... }:
delib.module {
  name = "krit.services.logitech.mouses.superlight";
  options = delib.singleEnableOption false;
  # Config is handled by logitech-main.nix which reads this enable flag
}
