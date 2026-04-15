{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech.mouses.superlight";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ pkgs.keyd ];

    boot.kernelModules = [ "uinput" ];

    services.keyd.enable = true;
    services.keyd.keyboards.superlight = {
      ids = [ "046d:c54d" ];
      settings = {
        main = {
          mouse1 = "C-c";
          mouse2 = "C-v";
        };
      };
    };
  };
}
