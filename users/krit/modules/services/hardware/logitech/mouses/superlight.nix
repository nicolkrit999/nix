{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech.mouses.superlight";
  options.krit.services.logitech.mouses.superlight = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    services.keyd = {
      keyboards = {
        superlight = {
          ids = [ "046d:c54d" ];
          settings = {
            main = {
              mouse1 = "C-c";
              mouse2 = "C-v";
            };
          };
        };
      };
    };
  };
}
