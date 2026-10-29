let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  mk = lib.mkForce;
  libDir = ../../lib;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  # Minimal-fixture twins (stylix is on by default there); each replaces the base16 scheme so the
  # palette is known, plus the theme constants. The real desktop is checked once at the end.
  desktop = flake.nixosConfigurations.nixos-desktop;
  mocha = import (libDir + "/scheme-catppuccin-mocha.nix");
  violet = import (libDir + "/scheme-darkviolet.nix");
  nt = import (libDir + "/scheme-windows-nt-light.nix");
  twin = scheme: extras: fx.mkNixos ([{ stylix.base16Scheme = mk scheme; myconfig.programs.cosmic.enable = mk true; }] ++ extras);
  plain = { myconfig.constants.theme.catppuccin = mk false; };

  darkT = twin violet [ plain ];
  lightT = twin nt [ plain { myconfig.constants.theme.polarity = mk "light"; } ];
  accentT = twin violet [ plain { myconfig.programs.cosmic.themeAccent = mk "base0E"; } ];
  catT = twin mocha [{
    myconfig.constants.theme.catppuccin = mk true;
    myconfig.constants.theme.catppuccinFlavor = mk "mocha";
    myconfig.constants.theme.catppuccinAccent = mk "mauve";
  }];
  latteT = twin mocha [{
    myconfig.constants.theme.catppuccin = mk true;
    myconfig.constants.theme.catppuccinFlavor = mk "latte";
    myconfig.constants.theme.catppuccinAccent = mk "blue";
  }];
  catOverrideT = twin mocha [{
    myconfig.constants.theme.catppuccin = mk true;
    myconfig.constants.theme.catppuccinFlavor = mk "mocha";
    myconfig.constants.theme.catppuccinAccent = mk "mauve";
    myconfig.programs.cosmic.themeAccent = mk "base08";
  }];
  noFollowT = twin violet [ plain { myconfig.programs.cosmic.followTheme = mk false; } ];
  offT = fx.mkNixos [{ stylix.base16Scheme = mk violet; myconfig.programs.cosmic.enable = mk false; }];

  cosmicOf = t: (fx.hmOf t).wayland.desktopManager.cosmic;
  themeOf = t: (cosmicOf t).appearance.theme;
  hasKey = t: k: (cosmicOf t).configFile ? ${k};

  legalSlots = [
    "accent_blue"
    "accent_green"
    "accent_indigo"
    "accent_orange"
    "accent_pink"
    "accent_purple"
    "accent_red"
    "accent_warm_grey"
    "accent_yellow"
    "bright_green"
    "bright_orange"
    "bright_red"
    "ext_blue"
    "ext_indigo"
    "ext_orange"
    "ext_pink"
    "ext_purple"
    "ext_warm_grey"
    "ext_yellow"
    "gray_1"
    "gray_2"
    "neutral_0"
    "neutral_1"
    "neutral_2"
    "neutral_3"
    "neutral_4"
    "neutral_5"
    "neutral_6"
    "neutral_7"
    "neutral_8"
    "neutral_9"
    "neutral_10"
  ];

  near = a: b: (if a > b then a - b else b - a) < 0.0005;
  hexRgb = h: {
    red = (lib.fromHexString (builtins.substring 0 2 h)) / 255.0;
    green = (lib.fromHexString (builtins.substring 2 2 h)) / 255.0;
    blue = (lib.fromHexString (builtins.substring 4 2 h)) / 255.0;
  };
  isHex = c: h: let e = hexRgb h; in near c.red e.red && near c.green e.green && near c.blue e.blue;
  inRange = c: lib.all (k: c.${k} >= 0.0 && c.${k} <= 1.0) [ "red" "green" "blue" ];

  builderOf = t: let th = themeOf t; in if th.mode == "light" then th.light else th.dark;
  paletteOf = t: lib.head (builderOf t).palette.value;
  accentOf = t: (builderOf t).accent.value;
  slotsOf = pal: lib.sort (a: b: a < b) (lib.filter (k: k != "name" && k != "_module") (builtins.attrNames pal));

  # Same predicate as lib.strings.floatToString: a float survives toString (6 decimals) unchanged.
  precise = x: builtins.isFloat x && x == builtins.fromJSON (toString x);
  preciseProblems = what: c:
    lib.concatMap (k: lib.optional (!(precise c.${k})) "${what}.${k} imprecise (${toString c.${k}})")
      (lib.filter (k: c ? ${k}) [ "red" "green" "blue" "alpha" ]);
  themeColours = t:
    let b = builderOf t; in
    lib.concatMap (k: preciseProblems k b.${k}.value) [ "accent" "destructive" "success" "warning" ]
    ++ lib.concatMap (k: preciseProblems k (paletteOf t).${k}) (slotsOf (paletteOf t));

  paletteProblems = pal:
    let
      extra = lib.subtractLists legalSlots (slotsOf pal);
      missing = lib.subtractLists (slotsOf pal) legalSlots;
      colourSlots = slotsOf pal;
    in
    lib.optional (extra != [ ]) "unknown palette slots ${builtins.toJSON extra}"
    ++ lib.optional (missing != [ ]) "missing palette slots ${builtins.toJSON missing}"
    ++ lib.optional (!(pal ? name) || !(builtins.isString pal.name)) "palette name missing"
    ++ lib.concatMap
      (k: lib.optional (!(inRange pal.${k}) || pal.${k}.alpha != 1.0) "slot ${k} out of range or not opaque")
      colourSlots;

  p = t: paletteOf t;
  slotIs = t: slot: hex: isHex (p t).${slot} hex;
  between = c: a: b: lib.all (k: (c.${k} >= (if a.${k} < b.${k} then a.${k} else b.${k}) - 0.0005) && (c.${k} <= (if a.${k} > b.${k} then a.${k} else b.${k}) + 0.0005)) [ "red" "green" "blue" ];
  pv = violet.palette;
  pn = nt.palette;
in
{
  results = {
    "theme: dark polarity sets mode dark, fills theme.dark, leaves theme.light null" =
      let th = themeOf darkT; in
      failIf (
        lib.optional (th.mode != "dark") "mode is ${builtins.toJSON th.mode}"
        ++ lib.optional (th.dark == null) "dark builder missing"
        ++ lib.optional (th.light != null) "light builder set on a dark twin"
      );
    "theme: light polarity sets mode light, fills theme.light, leaves theme.dark null" =
      let th = themeOf lightT; in
      failIf (
        lib.optional (th.mode != "light") "mode is ${builtins.toJSON th.mode}"
        ++ lib.optional (th.light == null) "light builder missing"
        ++ lib.optional (th.dark != null) "dark builder set on a light twin"
      );
    "theme: the polarity twins really differ in constants" =
      if darkT.config.myconfig.constants.theme.polarity == "dark" && lightT.config.myconfig.constants.theme.polarity == "light" then ok
      else "FAIL: polarity twins did not take the constant";
    "theme: palette enum variant is Dark for dark and Light for light" =
      let
        dv = (builderOf darkT).palette;
        lv = (builderOf lightT).palette;
      in
      failIf (
        lib.optional (dv.__type != "enum" || dv.variant != "Dark" || builtins.length dv.value != 1) "dark palette shape ${builtins.toJSON dv.variant}"
        ++ lib.optional (lv.__type != "enum" || lv.variant != "Light" || builtins.length lv.value != 1) "light palette shape ${builtins.toJSON lv.variant}"
      );
    "theme: dark mode never follows the accent (mode comes from polarity only)" =
      if (themeOf accentT).mode == "dark" && (themeOf catOverrideT).mode == "dark" && (themeOf latteT).mode == "dark" then ok
      else "FAIL: mode changed with the accent or the catppuccin flavor";
    "theme: Mode file is_dark follows polarity" =
      let
        d = (cosmicOf darkT).configFile."com.system76.CosmicTheme.Mode";
        l = (cosmicOf lightT).configFile."com.system76.CosmicTheme.Mode";
      in
      failIf (
        lib.optional (d.entries.is_dark != true) "dark twin is_dark"
        ++ lib.optional (l.entries.is_dark != false) "light twin is_dark"
      );
    "theme: Builder files are written for the active polarity only (version 2)" =
      let
        dk = "com.system76.CosmicTheme.Dark.Builder";
        lk = "com.system76.CosmicTheme.Light.Builder";
      in
      failIf (
        lib.optional (!(hasKey darkT dk) || hasKey darkT lk) "dark twin files"
        ++ lib.optional (!(hasKey lightT lk) || hasKey lightT dk) "light twin files"
        ++ lib.optional ((cosmicOf darkT).configFile.${dk}.version != 2) "builder version"
      );
    "theme: every palette key is a legal COSMIC slot, none missing, all opaque and in 0..1 (dark)" =
      failIf (paletteProblems (p darkT));
    "theme: every palette key is a legal COSMIC slot, none missing, all opaque and in 0..1 (light)" =
      failIf (paletteProblems (p lightT));
    "theme: every palette key is legal for catppuccin twins too" =
      failIf (paletteProblems (p catT) ++ paletteProblems (p latteT));
    "theme: srgb values of accent, destructive, success and warning are within 0..1" =
      let b = builderOf darkT; in
      failIf (lib.concatMap (k: lib.optional (!(inRange b.${k}.value)) "${k} out of range") [ "accent" "destructive" "success" "warning" ]);
    "theme: accent, destructive, success and warning are Some(srgb) without alpha" =
      let b = builderOf darkT; in
      failIf (lib.concatMap
        (k: lib.optional (b.${k}.__type != "optional" || b.${k}.value ? alpha || !(b.${k}.value ? red)) "${k} shape")
        [ "accent" "destructive" "success" "warning" ]);
    "theme: semantic colours come from base08 / base0B / base0A" =
      let b = builderOf darkT; in
      failIf (
        lib.optional (!(isHex b.destructive.value pv.base08)) "destructive"
        ++ lib.optional (!(isHex b.success.value pv.base0B)) "success"
        ++ lib.optional (!(isHex b.warning.value pv.base0A)) "warning"
      );
    "theme: default accent without catppuccin is base0D" =
      if isHex (accentOf darkT) pv.base0D then ok else "FAIL: accent is ${builtins.toJSON (accentOf darkT)}";
    "theme: themeAccent = base0E overrides the default accent" =
      if isHex (accentOf accentT) pv.base0E && !(isHex (accentOf accentT) pv.base0D) then ok
      else "FAIL: accent is ${builtins.toJSON (accentOf accentT)}";
    "theme: catppuccin on uses the catppuccinAccent colour (mocha mauve cba6f7)" =
      if isHex (accentOf catT) "cba6f7" then ok else "FAIL: accent is ${builtins.toJSON (accentOf catT)}";
    "theme: catppuccin flavor and accent are both honoured (latte blue 1e66f5)" =
      if isHex (accentOf latteT) "1e66f5" then ok else "FAIL: accent is ${builtins.toJSON (accentOf latteT)}";
    "theme: an explicit themeAccent wins over catppuccin (mocha red base08 f38ba8)" =
      if isHex (accentOf catOverrideT) mocha.palette.base08 && !(isHex (accentOf catOverrideT) "cba6f7") then ok
      else "FAIL: accent is ${builtins.toJSON (accentOf catOverrideT)}";
    "theme: grey ramp endpoints are base00 and base07 (gray_1, neutral_1, neutral_10)" =
      failIf (
        lib.optional (!(slotIs darkT "gray_1" pv.base00)) "gray_1"
        ++ lib.optional (!(slotIs darkT "gray_2" pv.base01)) "gray_2"
        ++ lib.optional (!(slotIs darkT "neutral_1" pv.base00)) "neutral_1"
        ++ lib.optional (!(slotIs darkT "neutral_2" pv.base01)) "neutral_2"
        ++ lib.optional (!(slotIs darkT "neutral_3" pv.base02)) "neutral_3"
        ++ lib.optional (!(slotIs darkT "neutral_10" pv.base07)) "neutral_10"
      );
    "theme: interpolated neutral_4 lies between base02 and base03" =
      if between (p darkT).neutral_4 (hexRgb pv.base02) (hexRgb pv.base03) then ok else "FAIL: neutral_4 outside base02..base03";
    "theme: hue slots map base08..base0F (red, orange, yellow, green, blue, purple, warm grey)" =
      failIf (
        lib.optional (!(slotIs darkT "accent_red" pv.base08)) "accent_red"
        ++ lib.optional (!(slotIs darkT "accent_orange" pv.base09)) "accent_orange"
        ++ lib.optional (!(slotIs darkT "accent_yellow" pv.base0A)) "accent_yellow"
        ++ lib.optional (!(slotIs darkT "accent_green" pv.base0B)) "accent_green"
        ++ lib.optional (!(slotIs darkT "accent_blue" pv.base0D)) "accent_blue"
        ++ lib.optional (!(slotIs darkT "accent_purple" pv.base0E)) "accent_purple"
        ++ lib.optional (!(slotIs darkT "accent_warm_grey" pv.base0F)) "accent_warm_grey"
        ++ lib.optional (!(slotIs darkT "ext_blue" pv.base0C)) "ext_blue"
      );
    "theme: indigo and pink are mixes of their neighbours" =
      failIf (
        lib.optional (!(between (p darkT).accent_indigo (hexRgb pv.base0D) (hexRgb pv.base0E))) "accent_indigo"
        ++ lib.optional (!(between (p darkT).accent_pink (hexRgb pv.base08) (hexRgb pv.base0E))) "accent_pink"
      );
    "theme: works for a second scheme (light NT scheme: ramp, hues and accent)" =
      failIf (
        lib.optional (!(slotIs lightT "gray_1" pn.base00)) "gray_1"
        ++ lib.optional (!(slotIs lightT "neutral_10" pn.base07)) "neutral_10"
        ++ lib.optional (!(slotIs lightT "accent_green" pn.base0B)) "accent_green"
        ++ lib.optional (!(isHex (accentOf lightT) pn.base0D)) "accent"
      );
    "theme: the two schemes produce different palettes (derived, not hardcoded)" =
      if (p darkT).gray_1 != (p lightT).gray_1 && (p darkT).accent_red != (p lightT).accent_red then ok else "FAIL: palettes equal across schemes";
    "theme: palette follows the scheme, not the polarity (dark constants with the light scheme)" =
      let t = twin nt [ plain ]; in
      if slotIs t "gray_1" pn.base00 && (themeOf t).mode == "dark" then ok else "FAIL: palette tied to polarity";
    "theme: followTheme = false emits no theme at all" =
      let th = themeOf noFollowT; in
      failIf (
        lib.optional (th.mode != null) "mode set"
        ++ lib.optional (th.dark != null) "dark set"
        ++ lib.optional (th.light != null) "light set"
        ++ lib.concatMap (k: lib.optional (hasKey noFollowT k) "${k} written")
          [ "com.system76.CosmicTheme.Mode" "com.system76.CosmicTheme.Dark.Builder" "com.system76.CosmicTheme.Light.Builder" ]
      );
    "theme: followTheme defaults to true" =
      if darkT.config.myconfig.programs.cosmic.followTheme then ok else "FAIL: followTheme default is false";
    "theme: cosmic off emits no theme" =
      let th = themeOf offT; in
      failIf (
        lib.optional (th.mode != null || th.dark != null || th.light != null) "theme set with cosmic off"
        ++ lib.optional (hasKey offT "com.system76.CosmicTheme.Mode") "Mode file with cosmic off"
      );
    "theme: toolkit (fonts, icons, density) is never touched" =
      failIf (lib.concatMap
        (t: lib.optional ((cosmicOf t).appearance.toolkit != null) "toolkit set"
          ++ lib.optional (hasKey t "com.system76.CosmicTk") "CosmicTk configFile written")
        [ darkT lightT accentT catT noFollowT ]);
    "theme: no corner radii, spacing, gaps or hint widths are written" =
      let b = builderOf darkT; in
      failIf (lib.concatMap (k: lib.optional (b.${k} or null != null) "${k} set") [ "corner_radii" "spacing" "gaps" "active_hint" "bg_color" "primary_container_bg" "secondary_container_bg" ]);
    "theme: real desktop follows the catppuccin sapphire accent in dark mode" =
      let
        t = { config = desktop.config; };
        th = themeOf t;
      in
      failIf (
        lib.optional (th.mode != "dark") "mode"
        ++ lib.optional (!(isHex (accentOf t) "74c7ec")) "accent ${builtins.toJSON (accentOf t)}"
        ++ lib.optional (!(slotIs t "gray_1" mocha.palette.base00)) "gray_1"
      );
    "theme: every colour float round-trips through toString (no floatToString imprecision warning)" =
      failIf (lib.concatMap themeColours [ darkT lightT accentT catT latteT catOverrideT { config = desktop.config; } ]);
    "theme: control, an unrounded byte/255 float is detected as imprecise" =
      detects "236/255" (preciseProblems "x" { red = 236 / 255.0; });
    "theme: control, an illegal slot name is detected" =
      detects "extra slot" (paletteProblems ((p darkT) // { accent_cyan = (p darkT).accent_blue; }));
    "theme: control, a missing slot is detected" =
      detects "missing slot" (paletteProblems (removeAttrs (p darkT) [ "neutral_10" ]));
    "theme: control, an out-of-range channel is detected" =
      detects "red 1.5" (paletteProblems ((p darkT) // { gray_1 = (p darkT).gray_1 // { red = 1.5; }; }));
    "theme: control, a translucent slot is detected" =
      detects "alpha 0.5" (paletteProblems ((p darkT) // { gray_1 = (p darkT).gray_1 // { alpha = 0.5; }; }));
    "theme: control, the accent comparison tells two colours apart" =
      detects "base0D vs base0E" (lib.optional (!(isHex (accentOf darkT) pv.base0E)) "differs");
  };
}
