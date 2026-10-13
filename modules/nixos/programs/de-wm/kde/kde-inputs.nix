{ delib
, lib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:

    lib.mkMerge [
      {
        programs.plasma.input.keyboard = {
          layouts = [
            {
              layout = myconfig.constants.keyboardLayout;
              variant = myconfig.constants.keyboardVariant;
            }
          ];
          numlockOnStartup = "on";
        };
      }
      (lib.mkIf (cfg.mice != [ ]) {
        programs.plasma.input.mice = cfg.mice;
      })
      (lib.mkIf (cfg.touchpads != [ ]) {
        programs.plasma.input.touchpads = cfg.touchpads;
      })
    ];
}
