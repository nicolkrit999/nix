let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  variant = builtins.getEnv "VARIANT";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  laptop = flake.nixosConfigurations.nixos-laptop;
  synthetic = programs: laptop.extendModules {
    modules = [{ myconfig.programs = lib.mapAttrs (_: lib.mkForce) ({ kde.enable = false; niri.enable = false; } // programs); }];
  };
  variants = {
    nixos-desktop = flake.nixosConfigurations.nixos-desktop;
    nixos-laptop = laptop;
    synthetic-caelestia = synthetic { caelestia.enable = true; };
    synthetic-noctalia = synthetic { noctalia.enable = true; };
  };
  sys = variants.${variant};

  c = sys.config;
  user = c.myconfig.constants.user;
  hm = c.home-manager.users.${user};
  home = hm.home.homeDirectory;
  en = n: c.myconfig.programs.${n}.enable or false;
  has = lib.hasInfix;

  strings = v:
    if builtins.isString v then [ v ]
    else if builtins.isList v then lib.concatMap strings v
    else if builtins.isAttrs v && !(lib.isDerivation v) then lib.concatMap strings (lib.attrValues v)
    else [ ];

  drvText = s:
    builtins.readFile (builtins.unsafeDiscardStringContext
      (lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext s)))));
  mkdirIn = text:
    let m = builtins.match ''.*mkdir -p [\\"]+([^\\" ]*)[\\"].*'' text;
    in if m == null then [ ] else m;
  scriptDir = s: mkdirIn (drvText s);
  first = pat: text:
    let m = builtins.match pat text; in if m == null then [ ] else [ (lib.head m) ];

  stripUrl = p: lib.removeSuffix "/" (lib.removePrefix "file://" p);
  dirOf' = p: lib.concatStringsSep "/" (lib.init (lib.splitString "/" p));

  luaText = hm.xdg.configFile."hypr/hyprland.lua".text or "";
  execOnce = c.myconfig.programs.hyprland.execOnce or [ ];
  mangoStrings = strings (hm.wayland.windowManager.mango or { });
  spectacle = hm.programs.plasma.configFile.spectaclerc or { };
  spectacleVal = sec: key: (spectacle.${sec}.${key} or { value = null; }).value;
  niriSettings = hm.programs.niri.settings or { };
  gnomeScripts = lib.filter (s: has "launch-screenshot" s)
    (map (v: v.command or "") (lib.attrValues (hm.dconf.settings or { })));

  src = name: expands: raw: { inherit name expands raw; };

  sources = lib.concatLists [
    (map (src "HM activation mkdir (createEssentialDirs)" true)
      (mkdirIn (hm.home.activation.createEssentialDirs.data or "")))
    (lib.optionals ((en "mango") || (en "cosmic"))
      (map (src "HM home.sessionVariables.XDG_SCREENSHOTS_DIR" true)
        (lib.optional (hm.home.sessionVariables ? XDG_SCREENSHOTS_DIR) hm.home.sessionVariables.XDG_SCREENSHOTS_DIR)))
    (lib.optionals (en "hyprland")
      (map (src "hyprland.lua env XDG_SCREENSHOTS_DIR" false)
        (first ''.*XDG_SCREENSHOTS_DIR"?[, =]+"([^"]*)".*'' luaText)))
    (lib.optionals (en "caelestia")
      (map (src "caelestia execOnce XDG_SCREENSHOTS_DIR=" true)
        (lib.concatMap (first ''.*XDG_SCREENSHOTS_DIR=([^ ']*).*'') execOnce)))
    (lib.optionals (en "mango")
      (map (src "mango autostart_sh export" true)
        (first ''.*export XDG_SCREENSHOTS_DIR="([^"]*)".*'' (hm.wayland.windowManager.mango.autostart_sh or ""))
      ++ map (src "mango-screenshot script" true)
        (lib.concatMap scriptDir (lib.take 1 (lib.filter (has "mango-screenshot") mangoStrings)))))
    (lib.optionals (en "niri")
      (map (src "niri environment XDG_SCREENSHOTS_DIR" false)
        (lib.optional (niriSettings.environment ? XDG_SCREENSHOTS_DIR) niriSettings.environment.XDG_SCREENSHOTS_DIR)
      ++ map (src "niri screenshot-path (dirname)" false)
        (lib.optional (niriSettings ? screenshot-path) (dirOf' niriSettings.screenshot-path))))
    (lib.optionals (en "gnome")
      (map (src "gnome launch-screenshot script" true)
        (lib.concatMap scriptDir (lib.take 1 gnomeScripts))))
    (lib.optionals (en "kde")
      (map (src "kde spectaclerc screenshotLocation" false)
        (lib.optional (spectacleVal "General" "screenshotLocation" != null) (stripUrl (spectacleVal "General" "screenshotLocation")))
      ++ map (src "kde spectaclerc imageSaveLocation" false)
        (lib.optional (spectacleVal "ImageSave" "imageSaveLocation" != null) (stripUrl (spectacleVal "ImageSave" "imageSaveLocation")))))
  ];

  normalise = p: builtins.replaceStrings [ "$HOME" ] [ home ] p;
  expected = normalise c.myconfig.constants.screenshots;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";

  wmWithSources = [ "hyprland" "mango" "niri" "gnome" "kde" "caelestia" "cosmic" ];
  hasSource = n: {
    hyprland = lib.any (s: has "hyprland.lua" s.name) sources;
    mango = lib.any (s: has "mango" s.name) sources;
    niri = lib.any (s: has "niri" s.name) sources;
    gnome = lib.any (s: has "gnome" s.name) sources;
    kde = lib.any (s: has "kde" s.name) sources;
    caelestia = lib.any (s: has "caelestia" s.name) sources;
    cosmic = hm.home.sessionVariables ? XDG_SCREENSHOTS_DIR;
  }.${n};
  distinct = lib.unique (map (s: normalise s.raw) sources);

  checks =
    {
      "every enabled screenshot-capable DE/WM has an extracted destination" =
        let missing = lib.filter (n: en n && !(hasSource n)) wmWithSources;
        in chk (missing == [ ]) "no destination extracted for: ${toString missing}";
      "all destinations identical (exact, case-sensitive) after HOME normalisation" =
        chk (builtins.length distinct <= 1) "differing destinations: ${lib.concatStringsSep " | " distinct}";
      "destinations equal the shared constant myconfig.constants.screenshots" =
        chk (distinct == [ ] || distinct == [ expected ]) "got ${lib.concatStringsSep " | " distinct}, want ${expected}";
      "no literal $HOME in a context that does not expand it" =
        let bad = lib.filter (s: !s.expands && has "$HOME" s.raw) sources;
        in chk (bad == [ ]) "unexpanded $HOME in: ${lib.concatStringsSep "; " (map (s: "${s.name}=${s.raw}") bad)}";
    }
    // lib.listToAttrs (map
      (s: {
        name = "[${s.name}] equals shared destination";
        value = chk (normalise s.raw == expected) "${s.raw} (normalised ${normalise s.raw}) != ${expected}";
      })
      sources);
in
{
  report = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (n: r: "${n}\t${r}") checks
      ++ [ "DEST\t${expected}" ]) + "\n";
}
