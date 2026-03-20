# This module configures KDE input devices, such as keyboards, mice, and touchpads using the community "plasma-manager" flake
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
              layout = myconfig.constants.keyboardLayout or "us";
              variant = myconfig.constants.keyboardVariant or "";
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
