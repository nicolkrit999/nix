let
  H = import ../shared/eval-scenario.nix;
  inherit (H) flake lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  mk = import (flake.outPath + "/modules/nixos/programs/de-wm/wallpaperd/mk-wallpaperd.nix") { inherit lib pkgs; };

  still = {
    targetMonitor = "*";
    wallpaperURL = "https://example.invalid/a.png";
    wallpaperSHA256 = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
    gifURL = "";
    gifSHA256 = "";
    videoURL = "";
    videoSHA256 = "";
  };
  deep = x: builtins.deepSeq x "ok";
  force = x: builtins.deepSeq (builtins.attrNames x) "ok";
  build = wallpapers: mk { wm = "hyprland"; inherit wallpapers; };

  hosts = [ "nixos-desktop" "nixos-laptop" ];
  wallpapersOf = h: flake.nixosConfigurations.${h}.config.myconfig.constants.wallpapers;
  nix32 = s: builtins.match "[0-9a-df-np-sv-z]{52}" s != null;
  hashOk = url: sha: url == "" || nix32 sha;
  entryOk = w: hashOk w.wallpaperURL w.wallpaperSHA256 && hashOk w.gifURL w.gifSHA256 && hashOk w.videoURL w.videoSHA256
    && (w.wallpaperURL != "" || w.gifURL != "" || w.videoURL != "");
  isVideo = w: w.videoURL != "" || w.gifURL != "";
  pathLine = drv: builtins.head (builtins.match ".*(export PATH=\"[^\n]*)\n.*" drv.package.text);
  hasInput = drv: name: lib.hasInfix "-${name}-" (pathLine drv);
  count = needle: hay: builtins.length (lib.splitString needle hay) - 1;
  guard = b: if b then "ok" else "FAIL";

  realFor = h:
    let
      ws = wallpapersOf h;
      targets = map (w: w.targetMonitor) ws;
      mkWm = wm: mk { inherit wm; wallpapers = ws; };
      hypr = mkWm "hyprland";
      mango = mkWm "mango";
      niri = mkWm "niri";
    in
    {
      nonEmpty = guard (ws != [ ]);
      hashes = guard (builtins.all entryOk ws);
      uniqueTargets = guard (builtins.length (lib.unique targets) == builtins.length targets);
      needsAwww = guard (hypr.needsAwww == builtins.any (w: !(isVideo w)) ws);
      needsMpv = guard (hypr.needsMpv == builtins.any isVideo ws);
      launcherText = builtins.unsafeDiscardStringContext hypr.launcher.text;
      mangoLauncherText = builtins.unsafeDiscardStringContext mango.launcher.text;
      niriArgvShape = guard (builtins.isList niri.startupArgv
        && builtins.all (c: builtins.isList c && builtins.all builtins.isString c) niri.startupArgv
        && (ws == [ ] || niri.startupArgv != [ ]));
      mangoNeedsRandr = guard (hasInput mango "wlr-randr");
      hyprNeedsSocat = guard (hasInput hypr "socat");
      niriNoWmTools = guard (!hasInput niri "wlr-randr" && !hasInput niri "socat");
      mpvExtraOnce = guard (count "WALLPAPERD_MPV_EXTRA=" hypr.launcher.text == 1);
      specCount = guard (builtins.length hypr.specs == builtins.length ws);
    };
  matrix =
    let
      video = still // { videoURL = "https://example.invalid/v.mp4"; videoSHA256 = still.wallpaperSHA256; };
      gif = still // { gifURL = "https://example.invalid/g.gif"; gifSHA256 = still.wallpaperSHA256; };
      flags = ws: let r = build ws; in "${toString r.needsAwww}/${toString r.needsMpv}";
      inputs = ws: let r = build ws; in guard (hasInput r "awww" == r.needsAwww && hasInput r "mpvpaper" == r.needsMpv);
    in
    {
      still = guard (flags [ still ] == "1/");
      video = guard (flags [ (video // { targetMonitor = "DP-1"; }) ] == "/1");
      gif = guard (flags [ gif ] == "/1");
      mixed = guard (flags [ still (video // { targetMonitor = "DP-1"; }) ] == "1/1");
      empty = guard (flags [ ] == "/");
      inputsStill = inputs [ still ];
      inputsVideo = inputs [ video ];
      inputsMixed = inputs [ still (gif // { targetMonitor = "DP-1"; }) ];
    };

  emptyHost = dir: H.getConfigWith [ (/. + builtins.unsafeDiscardStringContext flake.outPath + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix") ] dir H.nixosExtraX86;
  here = /. + builtins.unsafeDiscardStringContext flake.outPath + "/templates/tests/nixos/test-nixos-wallpapers";
  emptyWm = emptyHost (here + "/19-empty-wm");
  emptyGnomeCfg = emptyHost (here + "/20-empty-gnome");
  emptyKdeCfg = emptyHost (here + "/21-empty-kde");
  noStarWm = emptyHost (here + "/22-nostar-wm");
  noStarGnome = emptyHost (here + "/23-nostar-gnome");
  noStarKde = emptyHost (here + "/24-nostar-kde");
  starSecond = emptyHost (here + "/25-star-second");
  storePath = u: builtins.unsafeDiscardStringContext "${pkgs.fetchurl { url = u; sha256 = still.wallpaperSHA256; }}";
  firstPath = storePath "https://example.invalid/first-entry.png";
  secondPath = storePath "https://example.invalid/second-entry.png";
  picks = x: lib.hasInfix firstPath (builtins.unsafeDiscardStringContext (builtins.toJSON x))
    && !lib.hasInfix secondPath (builtins.unsafeDiscardStringContext (builtins.toJSON x))
    && !usesFallback x;
  hmEmpty = H.getHm emptyWm;

  lockHost = n: emptyHost (here + "/${n}");
  bgsOf = cfg: (H.getHm cfg).programs.hyprlock.settings.background;
  lockPath = n: storePath "https://example.invalid/${n}.png";
  # expect: [ { monitor; path } ] specific entries, catchAll: path of the monitor="" entry
  lockOk = { specific, catchAll }: bgs:
    let
      sp = lib.filter (b: b.monitor != "") bgs;
      ca = lib.filter (b: b.monitor == "") bgs;
      pathOf = b: builtins.unsafeDiscardStringContext b.path;
    in
    builtins.length ca == 1
    && pathOf (builtins.head ca) == catchAll
    && builtins.sort builtins.lessThan (map (b: b.monitor) sp) == builtins.sort builtins.lessThan (map (e: e.monitor) specific)
    && builtins.all (e: builtins.any (b: b.monitor == e.monitor && pathOf b == e.path) sp) specific
    && builtins.all (b: (builtins.head ca).zindex < b.zindex) sp;
  lookOn = b: b.blur_passes == 0 && b.color == "$base";
  lookOff = b: b.blur_passes != 0 && (b.color or "") != "$base";
  srcOf = cfg: (H.getHm cfg).programs.hyprlock.settings.source or [ ];
  ourConf = cfg: lib.filter (s: lib.hasSuffix "no-background.conf" (builtins.unsafeDiscardStringContext s)) (srcOf cfg);
  drvText = s: builtins.readFile (builtins.unsafeDiscardStringContext (builtins.head (builtins.attrNames (builtins.getContext s))));
  plainControl = pkgs.runCommand "plain-control" { } "echo x > $out";
  stripsBackground = t: lib.hasInfix "# BACKGROUND$/ { skip = 1" t && lib.hasInfix "hyprlock.conf" t && lib.hasInfix "grep -q '^background'" t;
  confOf = c: builtins.readFile (builtins.head (ourConf c));
  rawConf = c: builtins.readFile "${(H.getHm c).catppuccin.sources.hyprlock}/hyprlock.conf";
  secLines = text: sec:
    let
      ls = lib.splitString "\n" text;
      start = lib.lists.findFirstIndex (l: l == "# ${sec}") null ls;
      after = if start == null then [ ] else lib.drop (start + 1) ls;
    in
    lib.filter (l: l != "") (lib.take (let i = lib.lists.findFirstIndex (l: lib.hasPrefix "# " l) null after; in if i == null then builtins.length after else i) after);
  secVal = text: sec: key:
    let m = lib.filter (x: x != null) (map (l: builtins.match "  ${key} = (.*)" l) (secLines text sec));
    in if builtins.length m == 1 then builtins.head (builtins.head m) else "MISSING";
  untouchedSecs = [ "GENERAL" "LAYOUT" "FINGERPRINT" ];
  touchedSecs = [ "TIME" "DATE" "USER AVATAR" "INPUT FIELD" ];
  secsEqual = secs: a: b: builtins.all (s: secLines a s == secLines b s) secs;
  hlSettings = c: builtins.unsafeDiscardStringContext (builtins.toJSON (lib.filterAttrs (n: _: builtins.elem n [ "background" "image" "label" "input-field" ]) (H.getHm c).programs.hyprlock.settings));
  revertedSingleStar = path: [{ monitor = ""; inherit path; zindex = -1; }];
  desktopExpect = {
    specific = [{ monitor = "DP-1"; path = lockPath "lock-dp1"; } { monitor = "DP-2"; path = lockPath "lock-dp2"; }];
    catchAll = lockPath "lock-star";
  };
  desktopStatics = lib.filter (w: w.wallpaperURL != "") (wallpapersOf "nixos-desktop");
  desktopCatchAll = lib.findFirst (w: w.targetMonitor == "*") null desktopStatics;
  desktopSpecific = lib.filter (w: w.targetMonitor != "*") desktopStatics;
  desktopHm = H.getHm flake.nixosConfigurations.nixos-desktop.config;
  laptopWs = wallpapersOf "nixos-laptop";
  laptopEdp = lib.findFirst (w: w.targetMonitor == "eDP-1") null laptopWs;
  laptopStar = lib.findFirst (w: w.targetMonitor == "*") null laptopWs;
  fetchPath = w: builtins.unsafeDiscardStringContext "${pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; }}";
  laptopBgs = (H.getHm flake.nixosConfigurations.nixos-laptop.config).programs.hyprlock.settings.background;
  fb = emptyWm.myconfig.constants;
  fallbackPath = builtins.unsafeDiscardStringContext "${pkgs.fetchurl { url = fb.fallbackWallpaperURL; sha256 = fb.fallbackWallpaperSHA256; }}";
  usesFallback = x: lib.hasInfix fallbackPath (builtins.unsafeDiscardStringContext (builtins.toJSON x));
  videoGnomeCfg = emptyHost (here + "/30-video-only-gnome");
  videoKdeCfg = emptyHost (here + "/31-video-only-kde");
  explicitThird = storePath "https://example.invalid/explicit-third.png";
  videoOnlyPaths = [ (storePath "https://example.invalid/video-only-primary.mp4") (storePath "https://example.invalid/gif-only-second.gif") explicitThird ];
  kdeWallpapers = map builtins.unsafeDiscardStringContext (H.getHm videoKdeCfg).programs.plasma.workspace.wallpaper;
  mentions = needle: x: lib.hasInfix needle (builtins.unsafeDiscardStringContext (builtins.toJSON x));
  lap = flake.nixosConfigurations.nixos-laptop;
  videoOnlyEntry = still // { wallpaperURL = ""; wallpaperSHA256 = ""; videoURL = "https://example.invalid/stylix-video.mp4"; videoSHA256 = still.wallpaperSHA256; };
  lapImage = ws: builtins.unsafeDiscardStringContext "${(lap.extendModules { modules = [{ myconfig.constants.wallpapers = lib.mkForce ws; }]; }).config.stylix.image}";
in
{
  inherit matrix;
  videoOnlyPrimaryIsPrimary = guard (
    let p = videoGnomeCfg.myconfig.constants.primaryWallpaper;
    in p.wallpaperURL == "" && p.videoURL == "https://example.invalid/video-only-primary.mp4"
  );
  videoOnlyGnome = guard (
    usesFallback (H.getHm videoGnomeCfg).dconf.settings && !mentions "video-only-primary" (H.getHm videoGnomeCfg).dconf.settings
  );
  videoOnlyKdeEveryEntry = guard (kdeWallpapers == [ fallbackPath fallbackPath explicitThird ]);
  videoOnlyKscreenlocker = guard (
    let a = (H.getHm videoKdeCfg).programs.plasma.kscreenlocker.appearance;
    in usesFallback a && !mentions "explicit-third" a
  );
  videoOnlyStylix = guard (lapImage [ videoOnlyEntry ] == fallbackPath);
  explicitStylixKeepsOwn = guard (lapImage [ (videoOnlyEntry // { wallpaperURL = "https://example.invalid/explicit-stylix.png"; inherit (still) wallpaperSHA256; }) ] == storePath "https://example.invalid/explicit-stylix.png");
  videoOnlyMutantGnomeFails = guard (!usesFallback { picture-uri = "file://${storePath "https://example.invalid/video-only-primary.mp4"}"; });
  videoOnlyMutantKdeFails = guard (videoOnlyPaths != [ fallbackPath fallbackPath explicitThird ]);
  videoOnlyMutantStylixFails = guard (storePath videoOnlyEntry.videoURL != fallbackPath);
  emptyWmNoStartup = guard (
    !H.hyprExecHas "wallpaperd" emptyWm && !H.hyprExecHas "awww" emptyWm
    && !H.mangoExecHas "wallpaperd" emptyWm && !H.niriSpawnHas "wallpaperd" emptyWm
    && !H.niriSpawnHas "awww" emptyWm
  );
  emptyHyprlockFallback = guard (usesFallback hmEmpty.programs.hyprlock.settings.background
    && lockOk { specific = [ ]; catchAll = fallbackPath; } (bgsOf emptyWm));
  lockDesktop = guard (lockOk desktopExpect (bgsOf (lockHost "26-lock-desktop-like")));
  lockDesktopDistinct = guard (
    let ps = map (b: builtins.unsafeDiscardStringContext b.path) (bgsOf (lockHost "26-lock-desktop-like"));
    in builtins.length (lib.unique ps) == 3
  );
  lockControlRevertedFails = guard (!lockOk desktopExpect (revertedSingleStar (lockPath "lock-star")));
  lockControlRevertedHasNoSpecific = guard (builtins.length (bgsOf (lockHost "26-lock-desktop-like")) > 1);
  lockLaptopLike = guard (lockOk
    { specific = [{ monitor = "eDP-1"; path = lockPath "lock-edp1"; }]; catchAll = lockPath "lock-star"; }
    (bgsOf (lockHost "27-lock-laptop-like")));
  lockStarOnly = guard (lockOk { specific = [ ]; catchAll = lockPath "lock-star"; } (bgsOf (lockHost "28-lock-star-only")));
  lockDescVideo = guard (lockOk
    { specific = [{ monitor = "desc:Foo Bar 123"; path = lockPath "lock-desc"; }]; catchAll = fallbackPath; }
    (bgsOf (lockHost "29-lock-desc-video")));
  lockNoVideoPaths = guard (
    let j = builtins.unsafeDiscardStringContext (builtins.toJSON (bgsOf (lockHost "29-lock-desc-video")));
    in !lib.hasInfix "lock-dp3-video" j && !lib.hasInfix "lock-star-video" j && !lib.hasInfix "DP-3" j
  );
  lockRealLaptop = guard (laptopEdp != null && laptopStar != null && lockOk
    { specific = [{ monitor = "eDP-1"; path = fetchPath laptopEdp; }]; catchAll = fetchPath laptopStar; }
    laptopBgs);
  lockReal = guard (
    let
      dcfg = flake.nixosConfigurations.nixos-desktop.config;
      catppuccinOn = dcfg.myconfig.constants.theme.catppuccin;
      dbgs = desktopHm.programs.hyprlock.settings.background;
    in
    desktopStatics != [ ]
    && lockOk
      {
        specific = map (w: { monitor = w.targetMonitor; path = fetchPath w; }) desktopSpecific;
        catchAll = if desktopCatchAll != null then fetchPath desktopCatchAll else fallbackPath;
      }
      dbgs
    && (
      if catppuccinOn
      then desktopHm.catppuccin.hyprlock.enable && builtins.all lookOn dbgs
      else !desktopHm.catppuccin.hyprlock.enable && builtins.all lookOff dbgs && ourConf dcfg == [ ]
    )
  );
  lockCatppuccinDesktop = guard (
    let c = lockHost "34-lock-catppuccin-desktop"; bgs = bgsOf c;
    in (H.getHm c).catppuccin.hyprlock.enable && lockOk desktopExpect bgs
      && builtins.length bgs == 3 && builtins.all lookOn bgs
  );
  lockCatppuccinNoOwnBackgroundFile = guard (!((H.getHm (lockHost "34-lock-catppuccin-desktop")).xdg.configFile ? background));
  lockCatppuccinLookControl = guard (
    builtins.all lookOff (bgsOf (lockHost "26-lock-desktop-like"))
    && !builtins.any lookOn (bgsOf (lockHost "26-lock-desktop-like"))
  );
  lockCatppuccinOwnConfOnly = guard (
    let c = lockHost "34-lock-catppuccin-desktop";
    in !(H.getHm c).catppuccin.hyprlock.useDefaultConfig && builtins.length (srcOf c) == 3 && builtins.length (ourConf c) == 1
  );
  lockCatppuccinStripsBackground = guard (stripsBackground (drvText (builtins.head (ourConf (lockHost "34-lock-catppuccin-desktop")))));
  lockCatppuccinStripControl = guard (!stripsBackground (drvText "${plainControl}"));
  lockStripDrvs = pkgs.writeText "lock-strip-drvs" (builtins.head (ourConf (lockHost "34-lock-catppuccin-desktop")) + "${plainControl}");
  lockSizesDefaultsReproduceTheme = guard (
    let c = lockHost "34-lock-catppuccin-desktop"; g = confOf c; r = rawConf c;
    in builtins.all (s: secLines g s != [ ] && secLines g s == secLines r s) (untouchedSecs ++ touchedSecs)
  );
  lockSizesDefaultsAreThemeNumbers = guard (
    let g = confOf (lockHost "34-lock-catppuccin-desktop");
    in secVal g "TIME" "font_size" == "90" && secVal g "DATE" "font_size" == "25"
      && secVal g "DATE" "position" == "-30, -150" && secVal g "USER AVATAR" "size" == "100"
      && secVal g "USER AVATAR" "position" == "0, 75" && secVal g "INPUT FIELD" "size" == "300, 60"
  );
  lockSizesCustomApplied = guard (
    let g = confOf (lockHost "35-lock-catppuccin-sizes");
    in secVal g "USER AVATAR" "size" == "160" && secVal g "USER AVATAR" "position" == "0, 105"
      && secVal g "TIME" "font_size" == "120" && secVal g "DATE" "font_size" == "30"
      && secVal g "DATE" "position" == "-30, -180" && secVal g "INPUT FIELD" "size" == "350, 70"
  );
  lockSizesCustomOtherLinesUntouched = guard (
    let c = lockHost "35-lock-catppuccin-sizes"; g = confOf c; r = rawConf c;
    in secsEqual untouchedSecs g r
      && secVal g "TIME" "position" == secVal r "TIME" "position"
      && secVal g "DATE" "color" == secVal r "DATE" "color"
      && secVal g "USER AVATAR" "border_color" == secVal r "USER AVATAR" "border_color"
      && secVal g "INPUT FIELD" "position" == secVal r "INPUT FIELD" "position"
  );
  lockSizesCustomControlDiffers = guard (
    let g = confOf (lockHost "35-lock-catppuccin-sizes");
    in !secsEqual touchedSecs g (confOf (lockHost "34-lock-catppuccin-desktop"))
      && (lockHost "35-lock-catppuccin-sizes").myconfig.services.hyprlock.avatarSize == 160
  );
  lockSizesStillStripBackground = guard (
    let g = confOf (lockHost "35-lock-catppuccin-sizes");
    in !lib.hasInfix "# BACKGROUND" g && !lib.hasInfix "\nbackground" g
  );
  lockSizesIgnoredWithoutCatppuccin = guard (
    let off = lockHost "36-lock-sizes-catppuccin-off";
    in off.myconfig.services.hyprlock.avatarSize == 160 && !off.myconfig.constants.theme.catppuccin
      && ourConf off == [ ]
      && hlSettings off == hlSettings (lockHost "26-lock-desktop-like")
      && !lib.hasInfix "160" (hlSettings off) && !lib.hasInfix "350" (hlSettings off)
  );
  lockSizesOffControlDetectsChange = guard (hlSettings (lockHost "36-lock-sizes-catppuccin-off") != hlSettings (lockHost "34-lock-catppuccin-desktop"));
  lockCatppuccinOffNoStrip = guard (ourConf (lockHost "26-lock-desktop-like") == [ ]);
  lockNoStarOne = guard (lockOk { specific = [{ monitor = "eDP-1"; path = lockPath "lock-edp1"; }]; catchAll = fallbackPath; } (bgsOf (lockHost "32-lock-nostar-one")));
  lockNoStarThree = guard (lockOk
    {
      specific = map (n: { monitor = "DP-${toString n}"; path = lockPath "lock-dp${toString n}"; }) [ 1 2 3 ];
      catchAll = fallbackPath;
    }
    (bgsOf (lockHost "33-lock-nostar-three")));
  lockNoStarOnlyOneCatchAll = guard (
    let n = bs: builtins.length (lib.filter (b: b.monitor == "") bs);
    in n (bgsOf (lockHost "32-lock-nostar-one")) == 1 && n (bgsOf (lockHost "33-lock-nostar-three")) == 1
  );
  lockNoStarNotFirstStatic = guard (
    fallbackPath != lockPath "lock-edp1" && fallbackPath != lockPath "lock-dp1"
  );
  lockRealLaptopNotStar = guard (fetchPath laptopEdp != fetchPath laptopStar);
  emptyGnome = guard (usesFallback (H.getHm emptyGnomeCfg).dconf.settings);
  emptyKde = deep (H.getHm emptyKdeCfg).programs.plasma.workspace;
  emptyKscreenlocker = guard (usesFallback (H.getHm emptyKdeCfg).programs.plasma.kscreenlocker.appearance);
  noStarPrimary = guard (noStarWm.myconfig.constants.primaryWallpaper.wallpaperURL == "https://example.invalid/first-entry.png");
  noStarHyprlock = guard (lockOk
    {
      specific = [{ monitor = "DP-1"; path = firstPath; } { monitor = "HDMI-A-1"; path = secondPath; }];
      catchAll = fallbackPath;
    }
    (bgsOf noStarWm));
  noStarGnome = guard (picks (H.getHm noStarGnome).dconf.settings);
  noStarKscreenlocker = guard (picks (H.getHm noStarKde).programs.plasma.kscreenlocker.appearance);
  noStarStylixReadsPrimary =
    let src = builtins.readFile (flake.outPath + "/modules/nixos/toplevel/stylix-nixos.nix");
    in guard (lib.hasInfix "constants.primaryWallpaper" src && !lib.hasInfix "findFirst" src);
  starSecondPrimary = guard (starSecond.myconfig.constants.primaryWallpaper.wallpaperURL == "https://example.invalid/second-entry.png");
  fallbackConstantsSet = guard (fb.fallbackWallpaperURL != "" && nix32 fb.fallbackWallpaperSHA256);
  dupTarget = force (build [ still still ]);
  dollarParen = force (build [ (still // { targetMonitor = "$(hostname)"; }) ]);
  backtick = force (build [ (still // { targetMonitor = "`id`"; }) ]);
  control = force (build [ (still // { targetMonitor = "DP-1"; }) (still // { targetMonitor = "desc:Foo Bar 123"; }) (still // { targetMonitor = "*"; }) ]);
  real = lib.genAttrs hosts realFor;
}
