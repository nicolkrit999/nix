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
  fb = emptyWm.myconfig.constants;
  fallbackPath = builtins.unsafeDiscardStringContext "${pkgs.fetchurl { url = fb.fallbackWallpaperURL; sha256 = fb.fallbackWallpaperSHA256; }}";
  usesFallback = x: lib.hasInfix fallbackPath (builtins.unsafeDiscardStringContext (builtins.toJSON x));
in
{
  inherit matrix;
  emptyWmNoStartup = guard (
    !H.hyprExecHas "wallpaperd" emptyWm && !H.hyprExecHas "awww" emptyWm
    && !H.mangoExecHas "wallpaperd" emptyWm && !H.niriSpawnHas "wallpaperd" emptyWm
    && !H.niriSpawnHas "awww" emptyWm
  );
  emptyHyprlockFallback = guard (usesFallback hmEmpty.programs.hyprlock.settings.background);
  emptyGnome = guard (usesFallback (H.getHm emptyGnomeCfg).dconf.settings);
  emptyKde = deep (H.getHm emptyKdeCfg).programs.plasma.workspace;
  emptyKscreenlocker = guard (usesFallback (H.getHm emptyKdeCfg).programs.plasma.kscreenlocker.appearance);
  noStarPrimary = guard (noStarWm.myconfig.constants.primaryWallpaper.wallpaperURL == "https://example.invalid/first-entry.png");
  noStarHyprlock = guard (picks (H.getHm noStarWm).programs.hyprlock.settings.background);
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
  real = lib.genAttrs hosts (h: realFor h);
}
