let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  twin = modules: (fx.mkNixos modules).config;
  mk = lib.mkForce;
  over = lib.mkOverride 10;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  kdeOn = twin [{ myconfig.programs.kde.enable = mk true; }];
  kdeOff = twin [{ myconfig.programs.kde.enable = mk false; }];
  kdeBroken = twin [{
    myconfig.programs.kde.enable = mk true;
    security.wrappers.kwin_wayland.capabilities = over "cap_sys_nice+ep";
  }];

  kwinProblems = cfg:
    let w = cfg.security.wrappers; in
    if !(w ? kwin_wayland) then [ "kwin_wayland wrapper missing" ]
    else lib.optional (w.kwin_wayland.capabilities != "") "kwin_wayland capabilities are ${builtins.toJSON w.kwin_wayland.capabilities}";

  gnomeOn = twin [{ myconfig.programs.gnome.enable = mk true; }];
  gnomeBroken = twin [{
    myconfig.programs.gnome.enable = mk true;
    environment.gnome.excludePackages = over [ ];
    services.gnome.rygel.enable = over true;
  }];

  pnames = pkgs: map (p: lib.getName p) pkgs;
  sysNames = cfg: pnames cfg.environment.systemPackages;

  gnomeProblems = cfg:
    let
      ex = cfg.environment.gnome.excludePackages;
      exNames = pnames ex;
      leaked = lib.unique (builtins.filter (n: builtins.elem n (sysNames cfg)) exNames);
    in
    (lib.optional (ex == [ ]) "gnome excludePackages is empty")
    ++ (lib.optional (cfg.services.desktopManager.gnome.enable != true) "services.desktopManager.gnome.enable is not true")
    ++ (lib.optional cfg.services.gnome.rygel.enable "services.gnome.rygel.enable is true")
    ++ (map (n: "excluded package ${n} is still in systemPackages") leaked);

  cosmicOn = twin [{
    myconfig.programs.cosmic.enable = mk true;
    stylix.enable = mk true;
  }];
  cosmicOff = twin [{ myconfig.programs.cosmic.enable = mk false; }];

  tkRel = "share/cosmic/com.system76.CosmicTk/v1";
  tkPackage = cfg: lib.findFirst (p: lib.getName p == "cosmic-tk-fonts") null cfg.environment.systemPackages;

  fontFileProblems = family: file: text:
    (lib.optional (!(lib.hasInfix "family: \"${family}\"" text)) "${file} lacks family \"${family}\"")
    ++ (lib.optional (!(lib.hasInfix "weight: Normal" text)) "${file} lacks weight: Normal");

  tkProblems = cfg:
    let p = tkPackage cfg; in
    if p == null then [ "cosmic-tk-fonts package missing from systemPackages" ]
    else
      let
        read = f: builtins.readFile "${p}/${tkRel}/${f}";
        sans = cfg.stylix.fonts.sansSerif.name;
        mono = cfg.stylix.fonts.monospace.name;
      in
      (lib.optional (sans == mono) "sansSerif and monospace font names are equal, the check cannot tell the files apart")
      ++ fontFileProblems sans "interface_font" (read "interface_font")
      ++ fontFileProblems mono "monospace_font" (read "monospace_font");

  sampleFont = family: ''
    (
        family: "${family}",
        weight: Normal,
        stretch: Normal,
        style: Normal,
    )
  '';

  checks = {
    "kde: kwin_wayland wrapper exists with empty capabilities" = failIf (kwinProblems kdeOn);
    "kde: control, kde off has no kwin_wayland wrapper" =
      if kdeOff.security.wrappers ? kwin_wayland then "FAIL: kwin_wayland wrapper present with kde off, the kde check is vacuous" else ok;
    "control(kde): capability-bearing wrapper is detected" = detects "cap_sys_nice" (kwinProblems kdeBroken);

    "gnome: excludePackages set, none leaked into systemPackages, rygel off" = failIf (gnomeProblems gnomeOn);
    "control(gnome): emptied excludePackages and enabled rygel are detected" = detects "empty exclude list" (gnomeProblems gnomeBroken);
    "control(gnome): emptied excludePackages leaks packages into systemPackages" =
      let
        leaks = builtins.filter (n: builtins.elem n (sysNames (twin [{ myconfig.programs.gnome.enable = mk true; environment.gnome.excludePackages = over [ ]; }]))) (pnames gnomeOn.environment.gnome.excludePackages);
      in
      if leaks != [ ] then ok else "FAIL: control did not detect: exclusion has no observable effect";

    "cosmic: CosmicTk interface and monospace font files carry the stylix fonts" = failIf (tkProblems cosmicOn);
    "cosmic: control, cosmic off ships no cosmic-tk-fonts" =
      if tkPackage cosmicOff == null then ok else "FAIL: cosmic-tk-fonts present with cosmic off";
    "control(cosmic): swapped font files are detected" =
      detects "swapped fonts"
        (fontFileProblems cosmicOn.stylix.fonts.sansSerif.name "interface_font" (sampleFont cosmicOn.stylix.fonts.monospace.name));
    "control(cosmic): missing package is detected" = detects "no package" (tkProblems cosmicOff);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
