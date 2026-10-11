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

  checks = s:
    let
      c = s.config;
      hm = c.home-manager.users.krit;
      my = c.myconfig;
      cat = my.constants.theme.catppuccin;
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
    };

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

  perVariant = lib.mapAttrs (_: checks) variants;
  names = lib.attrNames (checks sys);
in
{
  report = lib.concatStringsSep "\n"
    (lib.concatMap (v: map (n: "${v}\t${n}\t${perVariant.${v}.${n}}") names) (lib.attrNames variants)
      ++ lib.mapAttrsToList (n: r: "files\t${n}\t${r}") fileChecks) + "\n";
  variants = lib.concatStringsSep " " (lib.attrNames variants);
}
