let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  force = attrs: sys.extendModules { modules = [{ myconfig.constants.theme = lib.mapAttrs (_: lib.mkForce) attrs; }]; };
  variants = {
    base = sys;
    catppuccin-on = force { catppuccin = true; };
    catppuccin-off = force { catppuccin = false; };
    light = force { polarity = "light"; };
  };
  noWallpapers = (force { catppuccin = false; }).extendModules { modules = [{ myconfig.constants.wallpapers = lib.mkForce [ ]; }]; };

  has = lib.hasInfix;
  forbiddenEnv = [ "XDG_CURRENT_DESKTOP" "XDG_SESSION_DESKTOP" "XDG_SESSION_TYPE" ];

  strings = v:
    if builtins.isString v then [ v ]
    else if builtins.isList v then lib.concatMap strings v
    else if builtins.isAttrs v then lib.concatMap strings (lib.attrValues v)
    else [ ];

  checksFor = catAssumed: s:
    let
      c = s.config;
      hm = c.home-manager.users.krit;
      my = c.myconfig;
      cat = if catAssumed == null then my.constants.theme.catppuccin else catAssumed;
      pol = my.constants.theme.polarity;
      dark = pol == "dark";
      darkInt = if dark then 1 else 0;
      chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
      want = n: my.stylix.targets.${n}.enable or (!cat);
      tgt = n: hm.stylix.targets.${n}.enable;
      mirrored = [ "bat" "lazygit" "starship" "gtk" "hyprlock" "hyprland" "swaync" "tmux" ];
      badTargets = lib.filter (n: tgt n != want n) mirrored;
      wm = (my.programs.hyprland.enable or false) || (my.programs.niri.enable or false) || (my.programs.mango.enable or false);
      kdePlat = (my.programs.hyprland.enable or false) || (my.programs.kde.enable or false);
      expectPlat = if kdePlat then "kde" else "qt5ct";
      scheme = if dark then "BreezeDark" else "BreezeLight";
      otherScheme = if dark then "BreezeLight" else "BreezeDark";
      qt6ct = hm.xdg.configFile."qt6ct/qt6ct.conf".text;
      hl = hm.programs.hyprlock.settings;
      hlStrings = strings hl;
      hlJoined = lib.concatStringsSep "\n" hlStrings;
      rgbaParts = lib.filter builtins.isList (builtins.split "rgba\\(([^)]*)\\)" hlJoined);
      badRgba = lib.filter (p: builtins.match "[0-9a-f]{8}" (lib.head p) == null) rgbaParts;
      placeholder = lib.concatStringsSep "\n" (map (i: i.placeholder_text or "") (hl.input-field or [ ]));
      envNames = lib.attrNames hm.home.sessionVariables
        ++ lib.attrNames c.environment.sessionVariables
        ++ lib.attrNames c.environment.variables
        ++ lib.attrNames c.systemd.globalEnvironment;
      leaked = lib.filter (n: lib.elem n forbiddenEnv) envNames;
      kdeOn = my.programs.kde.enable or false;
      stylixKde = tgt "kde";
      ws = hm.programs.plasma.workspace;
      cap = x: lib.toUpper (builtins.substring 0 1 x) + builtins.substring 1 (-1) x;
      catScheme = "Catppuccin${cap my.constants.theme.catppuccinFlavor}${cap my.constants.theme.catppuccinAccent}";
      catKde = (s.pkgs.catppuccin-kde.override {
        flavour = [ my.constants.theme.catppuccinFlavor ];
        accents = [ my.constants.theme.catppuccinAccent ];
      }).drvPath;
      hasCatKde = lib.any (p: (p.drvPath or "") == catKde) hm.home.packages;
    in
    {
      "HM stylix.targets.qt.enable is false" = chk (hm.stylix.targets.qt.enable == false) "HM qt target enabled";
      "stylix.targets.kde.enable == !catppuccin" = chk (tgt "kde" == !cat) "kde=${lib.boolToString (tgt "kde")} catppuccin=${lib.boolToString cat}";
      "stylix targets mirror catppuccin (bat lazygit starship gtk hyprlock hyprland swaync tmux)" =
        chk (badTargets == [ ]) "wrong: ${toString badTargets}";
      "stylix gnome/waybar/rofi/wofi/neovim targets stay off" =
        chk (lib.all (n: tgt n == false) [ "gnome" "waybar" "rofi" "wofi" "neovim" ]) "a hand-themed target is enabled";
      "gtk3/gtk4 prefer-dark follows polarity" =
        chk (hm.gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme == darkInt && hm.gtk.gtk4.extraConfig.gtk-application-prefer-dark-theme == darkInt)
          "gtk3=${toString hm.gtk.gtk3.extraConfig.gtk-application-prefer-dark-theme} polarity=${pol}";
      "NixOS and HM stylix.polarity equal the constant" =
        chk (c.stylix.polarity == pol && hm.stylix.polarity == pol) "nixos=${c.stylix.polarity} hm=${hm.stylix.polarity} const=${pol}";
      "catppuccin enable/autoEnable are true/false (system and HM)" =
        chk (c.catppuccin.enable && !c.catppuccin.autoEnable && hm.catppuccin.enable && !hm.catppuccin.autoEnable) "catppuccin enable/autoEnable drifted";
      "session env sets none of XDG_CURRENT_DESKTOP/XDG_SESSION_DESKTOP/XDG_SESSION_TYPE" =
        chk (leaked == [ ]) "set: ${toString leaked}";
      "QT_QPA_PLATFORMTHEME is kde iff hyprland or kde enabled" =
        chk (hm.home.sessionVariables.QT_QPA_PLATFORMTHEME == expectPlat) "got ${hm.home.sessionVariables.QT_QPA_PLATFORMTHEME}, want ${expectPlat}";
      "qt6ct color scheme file is declared and matches polarity" =
        chk
          (hm.xdg.dataFile ? "qt6ct/colors/${scheme}.colors"
            && has "/qt6ct/colors/${scheme}.colors" qt6ct
            && !(has "${otherScheme}.colors" qt6ct))
          "qt6ct.conf color_scheme_path does not point at a declared ${scheme} file";
      "programs.plasma.overrideConfig is true when KDE is enabled" =
        chk (!(my.programs.kde.enable or false) || hm.programs.plasma.overrideConfig == true) "plasma-manager overrideConfig is not true";
      "hyprlock catppuccin target matches theme mode" =
        chk (!wm || (hm.catppuccin.hyprlock.enable == cat)) "catppuccin.hyprlock.enable != catppuccin";
      "hyprlock: every rgba() is 8 lowercase hex digits (base16 mode)" =
        chk (!wm || cat || (rgbaParts != [ ] && badRgba == [ ])) "malformed: ${toString (map lib.head badRgba)} (found ${toString (lib.length rgbaParts)})";
      "hyprlock: pango foreground uses the hyprlang-escaped ## form (base16 mode)" =
        chk
          (!wm || cat || (builtins.match ".*foreground=\"##[0-9a-f]{6}[0-9a-f]{2}\".*" placeholder != null
            && builtins.match ".*foreground=\"#[^#].*" placeholder == null))
          "placeholder_text: ${placeholder}";
      "KDE: catppuccin-kde (flavour+accent from constants) is installed iff catppuccin" =
        chk (!kdeOn || hasCatKde == cat) "installed=${lib.boolToString hasCatKde} catppuccin=${lib.boolToString cat}";
      "KDE: plasma colorScheme and lookAndFeel are null iff the stylix KDE target is on" =
        chk (!kdeOn || ((ws.colorScheme == null && ws.lookAndFeel == null) == stylixKde))
          "stylixKde=${lib.boolToString stylixKde} colorScheme=${toString ws.colorScheme} lookAndFeel=${toString ws.lookAndFeel}";
      "KDE: catppuccin mode sets colorScheme Catppuccin<Flavor><Accent>" =
        chk (!kdeOn || !cat || stylixKde || ws.colorScheme == catScheme) "colorScheme=${toString ws.colorScheme}, want ${catScheme}";
      "KDE: stylix KDE target never owns the wallpaper (useWallpaper false)" =
        chk (hm.stylix.targets.kde.useWallpaper == false) "useWallpaper=${lib.boolToString hm.stylix.targets.kde.useWallpaper}";
      "KDE: plasma-manager still declares the wallpapers (list or custom plugin)" =
        chk (!kdeOn || (builtins.isList ws.wallpaper && ws.wallpaper != [ ]) || (ws.wallpaperCustomPlugin or null) != null) "no plasma wallpaper declared";
    };
  checks = checksFor null;

  sysOff = variants.catppuccin-off;
  sysOn = variants.catppuccin-on;
  kdeOnHost = sys.config.myconfig.programs.kde.enable or false;
  hmMutant = mod: sysOff.extendModules { modules = [{ home-manager.users.krit = mod; }]; };
  mutants = {
    "mutation: module ignores catppuccin (no catppuccin-kde) is caught" = {
      label = "KDE: catppuccin-kde (flavour+accent from constants) is installed iff catppuccin";
      r = checksFor true sysOff;
    };
    "mutation: colorScheme re-added next to the stylix KDE target is caught" = {
      label = "KDE: plasma colorScheme and lookAndFeel are null iff the stylix KDE target is on";
      r = checks (hmMutant { programs.plasma.workspace.colorScheme = lib.mkForce "BreezeDark"; });
    };
    "mutation: lookAndFeel re-added next to the stylix KDE target is caught" = {
      label = "KDE: plasma colorScheme and lookAndFeel are null iff the stylix KDE target is on";
      r = checks (hmMutant { programs.plasma.workspace.lookAndFeel = lib.mkForce "org.kde.breezedark.desktop"; });
    };
    "mutation: stylix useWallpaper true is caught" = {
      label = "KDE: stylix KDE target never owns the wallpaper (useWallpaper false)";
      r = checks (hmMutant { stylix.targets.kde.useWallpaper = lib.mkForce true; });
    };
    "mutation: wrong colorScheme in catppuccin mode is caught" = {
      label = "KDE: catppuccin mode sets colorScheme Catppuccin<Flavor><Accent>";
      r = checks (sysOn.extendModules { modules = [{ home-manager.users.krit.programs.plasma.workspace.colorScheme = lib.mkForce "BreezeDark"; }]; });
    };
    "mutation: wallpapers dropped from plasma is caught" = {
      label = "KDE: plasma-manager still declares the wallpapers (list or custom plugin)";
      r = checks (hmMutant {
        programs.plasma.workspace.wallpaper = lib.mkForce null;
        programs.plasma.workspace.wallpaperCustomPlugin = lib.mkForce null;
      });
    };
  };
  mutantLine = n:
    let m = mutants.${n}; r = m.r.${m.label}; in
    if !kdeOnHost then "ok"
    else if lib.hasPrefix "FAIL" r then "ok" else "FAIL: mutant not detected, check still passes";

  fallbackCheck =
    let
      c = noWallpapers.config;
      hm = c.home-manager.users.krit;
      my = c.myconfig;
      wm = (my.programs.hyprland.enable or false) || (my.programs.niri.enable or false) || (my.programs.mango.enable or false);
      expected = "${noWallpapers.pkgs.fetchurl { url = my.constants.fallbackWallpaperURL; sha256 = my.constants.fallbackWallpaperSHA256; }}";
      got = (lib.head hm.programs.hyprlock.settings.background).path;
    in
    if !wm then "ok" else if got == expected then "ok" else "FAIL: lock background is ${got}, want shared fallback ${expected}";

  fileChecks = {
    "hyprlock background uses the shared fallback wallpaper when wallpapers is empty" = fallbackCheck;
  };

  themed = force { base16Theme = "rose-pine-moon"; };
  stylixOff = themed.extendModules {
    modules = [
      { myconfig.stylix.enable = lib.mkForce false; }
    ];
  };
  fallbackPalette = { base00 = "1e1e2e"; base02 = "45475a"; base03 = "585b70"; base08 = "f38ba8"; base0D = "89b4fa"; };
  stylixPalette = themed.config.lib.stylix.colors;

  rendered = s:
    let
      c = s.config;
      hm = c.home-manager.users.krit;
      en = n: c.myconfig.programs.${n}.enable or false;
      safe = x: let r = builtins.tryEval (builtins.deepSeq x x); in if r.success then r.value else "EVAL ERROR";
      hy = hm.wayland.windowManager.hyprland.settings.config;
    in
    lib.optionalAttrs (en "hyprland")
      {
        "hyprland group active border" = safe hy.group."col.border_active";
        "hyprland background" = safe hy.misc.background_color;
        "hyprland inactive border" = safe hy.general."col.inactive_border";
      }
    // lib.optionalAttrs (en "mango") (
      let ms = hm.wayland.windowManager.mango.settings; in {
        "mango focus colour" = safe ms.focus_color;
        "mango root colour" = safe ms.root_color;
        "mango urgent colour" = safe ms.urgent_color;
      }
    )
    // lib.optionalAttrs (en "niri") (
      let fr = hm.programs.niri.settings.layout.focus-ring; in {
        "niri active ring" = safe fr.active.color;
        "niri inactive ring" = safe fr.inactive.color;
        "niri urgent ring" = safe fr.urgent.color;
      }
    );

  expectedFor = p: {
    "hyprland group active border" = "rgb(${p.base0D})";
    "hyprland background" = "rgb(${p.base00})";
    "hyprland inactive border" = "rgba(${p.base02}66)";
    "mango focus colour" = "0x${p.base0D}ff";
    "mango root colour" = "0x${p.base00}ff";
    "mango urgent colour" = "0x${p.base08}ff";
    "niri active ring" = "#${p.base0D}";
    "niri inactive ring" = "#${p.base03}";
    "niri urgent ring" = "#${p.base08}";
  };
  paletteCheck = s: p:
    let
      r = rendered s;
      e = expectedFor p;
    in
    lib.mapAttrs (n: v: if v == e.${n} then "ok" else "FAIL: got ${v}, want ${e.${n}}") r;
  offRes = paletteCheck stylixOff fallbackPalette;
  onRes = paletteCheck themed stylixPalette;
  allFail = r: r != { } && lib.all (lib.hasPrefix "FAIL") (lib.attrValues r);
  stubCheck =
    let
      c = stylixOff.config;
      hm = c.home-manager.users.krit;
      r = builtins.tryEval (builtins.deepSeq hm.programs.niri.settings.layout.focus-ring hm.stylix.enable);
    in
    if !(c.myconfig.programs.niri.enable or false) then "ok"
    else if r.success && r.value == false then "ok"
    else "FAIL: niri settings or the stub-provided hm.stylix.enable (false) do not evaluate with stylix off";
  paletteLines =
    lib.mapAttrsToList (n: r: "palette\tstylix off: ${n} is the catppuccin-mocha fallback\t${r}") offRes
    ++ lib.mapAttrsToList (n: r: "palette\tstylix on: ${n} is the stylix palette\t${r}") onRes
    ++ [
      "stub\tniri-stylix-off-enable-stub: niri settings evaluate with stylix off and no extra HM declaration\t${stubCheck}"
      "palette\tstylix off: at least one WM renders\t${if offRes != { } then "ok" else "FAIL: no hyprland/mango/niri enabled"}"
      "control\tmutation: stylix-on colours checked against the fallback palette are caught\t${if allFail (paletteCheck themed fallbackPalette) then "ok" else "FAIL: mutant not detected, stylix-on render equals the fallback"}"
      "control\tmutation: stylix-off colours checked against the stylix palette are caught\t${if allFail (paletteCheck stylixOff stylixPalette) then "ok" else "FAIL: mutant not detected, stylix-off render equals the stylix palette"}"
    ];

  perVariant = lib.mapAttrs (_: checks) variants;
  names = lib.attrNames (checks sys);
in
{
  report = lib.concatStringsSep "\n"
    (lib.concatMap (v: map (n: "${v}\t${n}\t${perVariant.${v}.${n}}") names) (lib.attrNames variants)
      ++ lib.mapAttrsToList (n: r: "files\t${n}\t${r}") fileChecks
      ++ paletteLines
      ++ map (n: "control\t${n}\t${mutantLine n}") (lib.attrNames mutants)) + "\n";
  variants = lib.concatStringsSep " " (lib.attrNames variants);
}
