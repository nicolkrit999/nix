{
  delib,
  lib,

  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:

    lib.mkMerge [
      # 🌟 RESTORED ORIGINAL KEYBOARD LOGIC
      {
        programs.plasma.input.keyboard = {
          layouts = [
            {
              layout = constants.keyboardLayout or "us";
              variant = constants.keyboardVariant or "";
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
