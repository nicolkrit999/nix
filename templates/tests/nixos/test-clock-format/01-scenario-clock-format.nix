# use24HourClock of services.sddm-astronaut, services.sddm-pixie and services.hyprlock.
# These three clocks ignore LC_TIME (LC_TIME cannot be split, and the greeter and the lock screen render
# their own format), so each has its own bool: false (default) = 12-hour, true = 24-hour. Contract:
#  - a host that does not set the option and a host that sets the default (false) give the same output
#  - true gives 24-hour, and the three options are independent of each other in one host
#  - themeConfig.HourFormat (astronaut) and themeConfig.use24HourClock (pixie) win over the option
#  - both hyprlock variants (catppuccin and plain) use the same clock token and the same date format
# Everything is asserted on built outputs (patched theme conf, theme.conf, generated lock conf) except the
# plain lock labels, which are the evaluated settings. Reads hosts from fixtures built from scratch.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  here = src + "/templates/tests/nixos/test-clock-format";
  noCtx = builtins.unsafeDiscardStringContext;

  fakeHosts = denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (here + "/host")
      (here + "/shared/nixos-extra")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/common/themes/catppuccin.nix")
      (src + "/modules/nixos/services/hypr/hyprlock.nix")
      (src + "/modules/nixos/services/sddm/sddm-astronaut.nix")
      (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
    ];
    exclude = [ ];
  };
  hosts = {
    astro = fakeHosts.clock-astronaut;
    pixie = fakeHosts.clock-pixie;
  };

  force = lib.mkOverride 10;
  mkModule = { astro ? null, pixie ? null, lock ? null, catppuccin ? false, embedded ? null, astroCfg ? { }, pixieCfg ? { }, pixieBg ? null, overlay ? null }:
    {
      config = lib.mkMerge [
        (lib.optionalAttrs (astro != null) { myconfig.services.sddm-astronaut.use24HourClock = astro; })
        (lib.optionalAttrs (pixie != null) { myconfig.services.sddm-pixie.use24HourClock = pixie; })
        (lib.optionalAttrs (lock != null) { myconfig.services.hyprlock.use24HourClock = lock; })
        (lib.optionalAttrs catppuccin { myconfig.constants.theme.catppuccin = force true; })
        (lib.optionalAttrs (embedded != null) { myconfig.services.sddm-astronaut.embeddedTheme = force embedded; })
        (lib.optionalAttrs (astroCfg != { }) { myconfig.services.sddm-astronaut.themeConfig = astroCfg; })
        (lib.optionalAttrs (pixieCfg != { }) { myconfig.services.sddm-pixie.themeConfig = pixieCfg; })
        (lib.optionalAttrs (pixieBg != null) { myconfig.services.sddm-pixie.background = "${pixieBg}"; })
        (lib.optionalAttrs (overlay != null) { nixpkgs.overlays = [ overlay ]; })
      ];
    };

  astroPkgOf = c: lib.findFirst (p: (p.name or "") == "sddm-astronaut-patched") null c.environment.systemPackages;
  pixiePkgOf = c: lib.findFirst (p: (p.pname or "") == "sddm-pixie") null c.environment.systemPackages;
  lockSources = hm: lib.filter (s: lib.hasSuffix "no-background.conf" (noCtx s)) (hm.programs.hyprlock.settings.source or [ ]);

  # kind: astro | pixie | stub. variant: plain (catppuccin off, lock labels from the evaluated settings) | cat (generated lock conf).
  scenario = _name: { host, spec ? { }, variant ? "plain", theme ? null, exp, kind }:
    let
      c = (hosts.${host}.extendModules { modules = [ (mkModule (spec // { catppuccin = variant == "cat"; })) ]; }).config;
      hm = c.home-manager.users.krit;
      labels = hm.programs.hyprlock.settings.label or [ ];
      astroPkg = astroPkgOf c;
      pixiePkg = pixiePkgOf c;
      lockConf = if variant == "cat" then lockConfOf hm else null;
    in
    {
      inherit kind variant exp;
      theme = if theme != null then theme else c.myconfig.services.sddm-astronaut.embeddedTheme or null;
      eff = {
        astro = if host == "astro" then c.myconfig.services.sddm-astronaut.use24HourClock else null;
        pixie = if host == "pixie" then c.myconfig.services.sddm-pixie.use24HourClock else null;
        lock = c.myconfig.services.hyprlock.use24HourClock;
      };
      plain =
        if variant == "plain" then {
          clocks = map (l: l.text) (lib.filter (l: (l.font_size or 0) == 55) labels);
          dates = map (l: l.text) (lib.filter (l: lib.hasInfix "date +" (l.text or "")) labels);
        } else null;
      drv = {
        theme = if variant == "plain" && astroPkg != null then noCtx astroPkg.drvPath else null;
        pixie = if variant == "plain" && pixiePkg != null then noCtx pixiePkg.drvPath else null;
        lockConf = if variant == "cat" then noCtx lockConf.drvPath else null;
      };
      pkgs = lib.optionalAttrs (variant == "plain" && astroPkg != null) { theme = astroPkg; }
        // lib.optionalAttrs (variant == "plain" && pixiePkg != null) { pixie = pixiePkg; }
        // lib.optionalAttrs (variant == "cat") { inherit lockConf; };
      rawLock = if variant == "cat" then rawLockOf hm else null;
    };

  lockConfOf = hm: pkgs.runCommand "lock-conf" { } ''cp ${builtins.head (lockSources hm)} $out'';
  rawLockOf = hm: pkgs.runCommand "lock-raw-theme" { } ''cp ${hm.catppuccin.sources.hyprlock}/hyprlock.conf $out'';

  clockCases = {
    unset = { spec = { }; exp = { astro = false; pixie = false; lock = false; }; };
    explicit-default = { spec = { astro = false; lock = false; }; exp = { astro = false; pixie = false; lock = false; }; };
    both24 = { spec = { astro = true; lock = true; }; exp = { astro = true; pixie = false; lock = true; }; };
    astro24-lock12 = { spec = { astro = true; }; exp = { astro = true; pixie = false; lock = false; }; };
    astro12-lock24 = { spec = { lock = true; }; exp = { astro = false; pixie = false; lock = true; }; };
  };
  pixieCases = {
    pixie-unset = { spec = { }; exp = { astro = false; pixie = false; lock = false; }; };
    pixie-explicit-default = { spec = { pixie = false; lock = false; }; exp = { astro = false; pixie = false; lock = false; }; };
    pixie24-lock12 = { spec = { pixie = true; }; exp = { astro = false; pixie = true; lock = false; }; };
    pixie12-lock24 = { spec = { lock = true; }; exp = { astro = false; pixie = false; lock = true; }; };
    pixie-bg-unset = { spec = { pixieBg = wallpaper; }; exp = { astro = false; pixie = false; lock = false; }; };
    pixie-bg-24 = { spec = { pixieBg = wallpaper; pixie = true; }; exp = { astro = false; pixie = true; lock = false; }; };
    pixie-override-true = { spec = { pixieCfg.use24HourClock = "true"; }; exp = { astro = false; pixie = false; lock = false; override = "true"; }; };
    pixie-override-false = { spec = { pixie = true; pixieCfg.use24HourClock = "false"; }; exp = { astro = false; pixie = true; lock = false; override = "false"; }; };
  };

  wallpaper = pkgs.runCommand "clock-format-bg.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick -size 64x64 xc:'#808080' png:$out
  '';

  stubTheme = hasKey: pkgs.runCommand "sddm-astronaut-stub" { } ''
    d=$out/share/sddm/themes/sddm-astronaut-theme/Themes
    mkdir -p "$d"
    printf 'Font="x"\n${lib.optionalString hasKey ''HourFormat="HH:mm"\n''}' > "$d/hyprland_kath.conf"
  '';
  stubOverlay = hasKey: _final: _prev: { sddm-astronaut = lib.makeOverridable (_: stubTheme hasKey) { }; };

  noExp = { astro = false; pixie = false; lock = false; };
  scenarios =
    lib.concatMapAttrs
      (n: v: {
        ${n} = scenario n { host = "astro"; inherit (v) spec exp; kind = "astro"; };
        "${n}-cat" = scenario "${n}-cat" { host = "astro"; inherit (v) spec exp; variant = "cat"; kind = "astro"; };
      })
      clockCases
    // lib.mapAttrs (n: v: scenario n { host = "pixie"; inherit (v) spec exp; kind = "pixie"; }) pixieCases
    // {
      cyber-12h = scenario "cyber-12h" { host = "astro"; spec.embedded = "cyberpunk"; exp = noExp; kind = "astro"; };
      cyber-24h = scenario "cyber-24h" { host = "astro"; spec = { embedded = "cyberpunk"; astro = true; }; exp = noExp // { astro = true; }; kind = "astro"; };
      override-hourformat = scenario "override-hourformat" {
        host = "astro";
        spec.astroCfg.HourFormat = "HH:mm:ss";
        exp = noExp // { override = "HH:mm:ss"; };
        kind = "astro";
      };
      stub-with-key = scenario "stub-with-key" { host = "astro"; spec.overlay = stubOverlay true; exp = noExp; kind = "stub"; };
      stub-missing-key = scenario "stub-missing-key" { host = "astro"; spec.overlay = stubOverlay false; exp = noExp; kind = "stub"; };
    };

  expectFail = [ "stub-missing-key" ];
  built = lib.filterAttrs (n: _: !(builtins.elem n expectFail)) scenarios;
  refTheme = t: hosts.astro.pkgs.sddm-astronaut.override { embeddedTheme = t; };
  refs = {
    hyprland_kath = refTheme "hyprland_kath";
    cyberpunk = refTheme "cyberpunk";
    rawLock = scenarios.unset-cat.rawLock;
  };
  hostSources = lib.concatMapStrings (f: builtins.readFile (here + "/host/${f}")) [ "astronaut.nix" "pixie.nix" ];

  meta = {
    scenarios = lib.mapAttrs (_: s: { inherit (s) kind variant exp theme eff plain drv; }) scenarios;
    inherit expectFail;
    fixtureSetsOption = lib.hasInfix "use24HourClock" hostSources;
  };
  entries = lib.concatLists (lib.mapAttrsToList (n: s: lib.mapAttrsToList (k: d: { name = "${n}.${k}"; path = d; }) s.pkgs) built)
    ++ lib.mapAttrsToList (k: d: { name = "ref.${k}"; path = d; }) refs;
in
{
  inherit meta;
  all = pkgs.linkFarm "clock-format-all" ([{ name = "meta.json"; path = pkgs.writeText "clock-format-meta.json" (builtins.toJSON meta); }] ++ entries);
  buildAttrs = lib.concatLists (lib.mapAttrsToList (n: s: map (k: "pkg.${n}.${k}") (builtins.attrNames s.pkgs)) built)
    ++ map (k: "ref.${k}") (builtins.attrNames refs);
  pkg = lib.mapAttrs (_: s: s.pkgs) scenarios;
  ref = refs;
}
