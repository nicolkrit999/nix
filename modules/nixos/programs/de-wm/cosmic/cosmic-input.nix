{ delib
, lib
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      optional = value: {
        __type = "optional";
        inherit value;
      };
      enum = variant: {
        __type = "enum";
        inherit variant;
      };
      orNull = f: v: if v == null then null else f v;

      inputStruct = { tap ? null, natural, dwt ? null, profile, speed }: {
        state = enum "Enabled";
        acceleration = optional {
          profile = optional (orNull enum profile);
          speed = if speed == null then 0.0 else speed * 1.0;
        };
        calibration = optional null;
        click_method = optional null;
        disable_while_typing = optional dwt;
        left_handed = optional null;
        map_to_output = optional null;
        middle_button_emulation = optional null;
        rotation_angle = optional null;
        scroll_config = optional {
          method = optional null;
          natural_scroll = optional natural;
          scroll_button = optional null;
          scroll_factor = optional null;
        };
        tap_config = optional {
          button_map = optional null;
          drag = true;
          drag_lock = false;
          enabled = if tap == null then true else tap;
        };
      };

      touchpadSet = lib.any (v: v != null) [
        cfg.touchpadTapToClick
        cfg.touchpadNaturalScroll
        cfg.touchpadDisableWhileTyping
        cfg.touchpadAccelProfile
        cfg.touchpadSpeed
      ];
      mouseSet = lib.any (v: v != null) [
        cfg.mouseNaturalScroll
        cfg.mouseAccelProfile
        cfg.mouseSpeed
      ];
    in
    {
      wayland.desktopManager.cosmic.compositor = lib.mkMerge [
        {
          xkb_config = {
            rules = "";
            model = "pc104";
            layout = myconfig.constants.keyboardLayout;
            variant = myconfig.constants.keyboardVariant;
            options = optional (if myconfig.constants.keyboardOptions == "" then null else myconfig.constants.keyboardOptions);
            repeat_delay = if cfg.keyboardRepeatDelay == null then 600 else cfg.keyboardRepeatDelay;
            repeat_rate = if cfg.keyboardRepeatRate == null then 25 else cfg.keyboardRepeatRate;
          };
          keyboard_config.numlock_state = enum "BootOn";
        }
        (lib.mkIf touchpadSet {
          input_touchpad = inputStruct {
            tap = cfg.touchpadTapToClick;
            natural = cfg.touchpadNaturalScroll;
            dwt = cfg.touchpadDisableWhileTyping;
            profile = cfg.touchpadAccelProfile;
            speed = cfg.touchpadSpeed;
          };
        })
        (lib.mkIf mouseSet {
          input_default = inputStruct
            {
              natural = cfg.mouseNaturalScroll;
              profile = cfg.mouseAccelProfile;
              speed = cfg.mouseSpeed;
            } // { tap_config = optional null; };
        })
      ];
    };
}
