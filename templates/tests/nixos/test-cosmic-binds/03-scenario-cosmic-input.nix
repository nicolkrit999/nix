let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  mk = lib.mkForce;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  twin = extra: fx.mkNixos [{ myconfig.programs.cosmic.enable = mk true; } extra];
  plain = twin { };
  touch = twin {
    myconfig.programs.cosmic.touchpadTapToClick = mk true;
    myconfig.programs.cosmic.touchpadNaturalScroll = mk true;
    myconfig.programs.cosmic.touchpadDisableWhileTyping = mk true;
    myconfig.programs.cosmic.touchpadAccelProfile = mk "Flat";
    myconfig.programs.cosmic.touchpadSpeed = mk 0.5;
  };
  mouse = twin {
    myconfig.programs.cosmic.mouseNaturalScroll = mk false;
    myconfig.programs.cosmic.mouseAccelProfile = mk "Adaptive";
    myconfig.programs.cosmic.mouseSpeed = mk (-0.25);
  };
  repeat = twin {
    myconfig.programs.cosmic.keyboardRepeatDelay = mk 300;
    myconfig.programs.cosmic.keyboardRepeatRate = mk 40;
  };
  off = fx.mkNixos [{ myconfig.programs.cosmic.enable = mk false; myconfig.programs.cosmic.touchpadTapToClick = mk true; }];

  compOf = t: (fx.hmOf t).wayland.desktopManager.cosmic.compositor;
  constsOf = t: t.config.myconfig.constants;
  opt = v: { __type = "optional"; value = v; };
  en = v: { __type = "enum"; variant = v; };

  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;

  has = a: k: (a.${k} or null) != null;
  scrollNatural = c: c.scroll_config.value.natural_scroll;
in
{
  results = {
    "input: xkb layout and variant equal the constants (same source as KDE)" =
      let c = compOf plain; k = constsOf plain; in
      if c.xkb_config.layout == k.keyboardLayout && c.xkb_config.variant == k.keyboardVariant then ok
      else "FAIL: xkb is ${builtins.toJSON c.xkb_config}";
    "input: xkb options equal the constants (Hyprland kb_options)" =
      let x = (compOf plain).xkb_config; k = constsOf plain; in
      if x.options == opt (if k.keyboardOptions == "" then null else k.keyboardOptions) then ok
      else "FAIL: xkb options are ${builtins.toJSON x.options}";
    "input: xkb options follow a declared constant, and empty gives None" =
      let
        o = s: (compOf (twin { myconfig.constants.keyboardOptions = mk s; })).xkb_config.options;
      in
      if o "caps:escape" == opt "caps:escape" && o "" == opt null then ok else "FAIL: options not derived from the constant";
    "input: xkb keeps COSMIC defaults for rules, model and repeat" =
      let x = (compOf plain).xkb_config; in
      if x.rules == "" && x.model == "pc104" && x.repeat_delay == 600 && x.repeat_rate == 25 then ok
      else "FAIL: xkb is ${builtins.toJSON x}";
    "input: declared repeat delay and rate are used" =
      let x = (compOf repeat).xkb_config; in
      if x.repeat_delay == 300 && x.repeat_rate == 40 then ok else "FAIL: xkb is ${builtins.toJSON x}";
    "input: numlock is BootOn" =
      if (compOf plain).keyboard_config.numlock_state == en "BootOn" then ok else "FAIL: numlock not BootOn";
    "input: nothing set emits neither input_touchpad nor input_default" =
      let c = compOf plain; in
      if !(has c "input_touchpad") && !(has c "input_default") then ok else "FAIL: input keys emitted by default";
    "input: touchpad values land in input_touchpad" =
      let c = (compOf touch).input_touchpad; in
      failIf (
        lib.optional (c.tap_config.value.enabled != true) "tap enabled"
        ++ lib.optional (scrollNatural c != opt true) "natural scroll"
        ++ lib.optional (c.disable_while_typing != opt true) "disable while typing"
        ++ lib.optional (c.acceleration.value.profile != opt (en "Flat")) "profile"
        ++ lib.optional (c.acceleration.value.speed != 0.5) "speed"
        ++ lib.optional (c.state != en "Enabled") "state"
      );
    "input: touchpad options do not create input_default" =
      if !(has (compOf touch) "input_default") then ok else "FAIL: input_default emitted for touchpad-only twin";
    "input: mouse values land in input_default, with no tap config" =
      let c = (compOf mouse).input_default; in
      failIf (
        lib.optional (scrollNatural c != opt false) "natural scroll"
        ++ lib.optional (c.acceleration.value.profile != opt (en "Adaptive")) "profile"
        ++ lib.optional (c.acceleration.value.speed != -0.25) "speed"
        ++ lib.optional (c.tap_config != opt null) "tap_config not None"
      );
    "input: mouse options do not create input_touchpad" =
      if !(has (compOf mouse) "input_touchpad") then ok else "FAIL: input_touchpad emitted for mouse-only twin";
    "input: unset touchpad fields stay None (libinput default)" =
      let c = (compOf (twin { myconfig.programs.cosmic.touchpadTapToClick = mk false; })).input_touchpad; in
      failIf (
        lib.optional (c.tap_config.value.enabled != false) "tap not false"
        ++ lib.optional (scrollNatural c != opt null) "natural scroll not None"
        ++ lib.optional (c.disable_while_typing != opt null) "dwt not None"
        ++ lib.optional (c.acceleration.value.profile != opt null) "profile not None"
      );
    "input: explicit false is emitted as Some(false), not None" =
      let
        c = (compOf (twin {
          myconfig.programs.cosmic.touchpadNaturalScroll = mk false;
          myconfig.programs.cosmic.touchpadDisableWhileTyping = mk false;
        })).input_touchpad;
      in
      failIf (
        lib.optional (scrollNatural c != opt false) "natural scroll not Some(false)"
        ++ lib.optional (c.disable_while_typing != opt false) "dwt not Some(false)"
      );
    "real desktop: xkb layout, variant and options equal the constants" =
      let
        x = (compOf desktop).xkb_config;
        k = constsOf desktop;
      in
      failIf (
        lib.optional (x.layout != k.keyboardLayout) "layout"
        ++ lib.optional (x.variant != k.keyboardVariant) "variant"
        ++ lib.optional (x.options != opt (if k.keyboardOptions == "" then null else k.keyboardOptions)) "options"
      );
    "real desktop: numlock is BootOn" =
      if (compOf desktop).keyboard_config.numlock_state == en "BootOn" then ok else "FAIL: numlock not BootOn";
    "real desktop: touchpad tap on, natural scroll off, disable-while-typing on" =
      let c = (compOf desktop).input_touchpad; in
      failIf (
        lib.optional (c.tap_config.value.enabled != true) "tap"
        ++ lib.optional (scrollNatural c != opt false) "natural scroll"
        ++ lib.optional (c.disable_while_typing != opt true) "dwt"
      );
    "real desktop: mouse natural scroll off" =
      if scrollNatural (compOf desktop).input_default == opt false then ok else "FAIL: mouse natural scroll not Some(false)";
    "real laptop: declares the same input options as the desktop (cosmic itself is off there)" =
      let c = laptop.config.myconfig.programs.cosmic; in
      failIf (
        lib.optional (c.touchpadTapToClick != true) "tap"
        ++ lib.optional (c.touchpadNaturalScroll != false) "touchpad natural scroll"
        ++ lib.optional (c.touchpadDisableWhileTyping != true) "dwt"
        ++ lib.optional (c.mouseNaturalScroll != false) "mouse natural scroll"
      );
    "input: control, cosmic off sets no compositor config" =
      if (fx.hmOf off).wayland.desktopManager.cosmic.compositor == null then ok else "FAIL: compositor set with cosmic off";
    "input: control, a wrong expectation is detected" =
      detects "wrong speed" (lib.optional ((compOf touch).input_touchpad.acceleration.value.speed != 0.9) "speed differs");
  };
}
