{ delib, ... }:
delib.module {
  name = "krit-superlight";

  nixos.always = {
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
