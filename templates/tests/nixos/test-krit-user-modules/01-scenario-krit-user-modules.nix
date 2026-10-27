let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  inherit (flake.inputs.nixpkgs) lib;
  fx = import ../../lib/fixture-host.nix flake;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  twin = modules: (fx.mkNixos modules).config;
  hm = c: c.home-manager.users.${c.myconfig.constants.user};
  show = builtins.toJSON;

  mice = { mx3s, mx4 }: {
    myconfig.krit.services.logitech = {
      enable = true;
      mouses.mx-master-3s.enable = mx3s;
      mouses.mx-master-4.enable = mx4;
    };
  };

  none = twin [ ];
  dolphin = twin [{ myconfig.krit.programs.dolphin.enable = true; }];
  pwa = twin [{ myconfig.krit.programs.pwas.enable = true; }];
  heliumOnly = twin [{ myconfig.krit.programs.helium.enable = true; }];
  both = twin [{ myconfig.krit.programs = { helium.enable = true; chromium.enable = true; }; }];
  logid = twin [ (mice { mx3s = true; mx4 = true; }) ];
  only4 = twin [ (mice { mx3s = false; mx4 = true; }) ];
  noMice = twin [ (mice { mx3s = false; mx4 = false; }) ];

  failing = needle: c: lib.filter (x: lib.hasInfix needle x.message) (lib.filter (x: !x.assertion) c.assertions);
  xorMsg = "krit.programs.helium and krit.programs.chromium are mutually exclusive";

  pkgNames = c: map lib.getName (c.environment.systemPackages ++ (hm c).home.packages);
  count = n: c: lib.length (lib.filter (x: x == n) (pkgNames c));
  dolphinrc = (hm dolphin).xdg.configFile."dolphinrc".text;
  pluginsLines = text: lib.filter (l: lib.hasPrefix "Plugins=" (lib.trim l)) (lib.splitString "\n" text);
  places = (hm dolphin).home.activation.createDolphinPlaces.data;
  placesWired = text: lib.hasInfix "/bin/dolphin-places-sync " text && lib.hasInfix "-user-places.xbel " text
    && lib.hasInfix "${(hm dolphin).home.homeDirectory}/.local/share/user-places.xbel" text && lib.hasInfix "--last trash:/" text;

  pwaEntries = c: lib.filterAttrs (n: _: lib.hasPrefix "pwa-" n) (hm c).xdg.desktopEntries;
  pwas = pwaEntries pwa;
  pwaProblems = entries: lib.concatLists (lib.mapAttrsToList
    (n: e:
      lib.optional ((e.mimeType or [ ]) != [ ] && (e.mimeType or null) != null) "${n}: mimeType ${show e.mimeType}"
      ++ lib.optional ((e.categories or [ ]) != [ "Network" ]) "${n}: categories ${show (e.categories or [ ])}")
    entries);

  c548 = "ATTR{idProduct}==\"c548\"";
  c548Count = c: lib.length (lib.splitString c548 c.services.udev.extraRules) - 1;
  logidTriggers = c: c.systemd.services.logid.restartTriggers;
  logidSrc = c: c.environment.etc."logid.cfg".source;

  checks = {
    check-dolphin-resets-exclude-dolphinrc = check (lib.elem "dolphinrc" (hm dolphin).programs.plasma.resetFilesExclude)
      "programs.plasma.resetFilesExclude is ${show (hm dolphin).programs.plasma.resetFilesExclude}, lacks dolphinrc";
    check-dolphinrc-no-plugins-line = check (pluginsLines dolphinrc == [ ] && lib.hasInfix "[General]" dolphinrc)
      "dolphinrc has Plugins= lines (the hand-written plugin list hides new thumbnailers): ${show (pluginsLines dolphinrc)}";
    check-dolphin-thumbnailers-installed = check
      (lib.elem "kdegraphics-thumbnailers" (pkgNames dolphin) && lib.elem "ffmpegthumbs" (pkgNames dolphin))
      "kdegraphics-thumbnailers / ffmpegthumbs missing from the packages";
    check-dolphin-installed-at-most-once = check (count "dolphin" dolphin <= 1)
      "dolphin installed ${toString (count "dolphin" dolphin)} times (dolphin.nix must not add kdePackages.dolphin)";
    check-dolphin-places-sync-wired = check
      (placesWired places && !(placesWired "run something-else"))
      "createDolphinPlaces does not run dolphin-places-sync with the seed file, the live user-places.xbel and --last trash:/";
    check-control-plugins-line-detected = check (pluginsLines "[General]\nPlugins=a,b\n" == [ "Plugins=a,b" ])
      "the Plugins= lint does not flag a planted line";

    check-control-no-dolphin-no-contract = check
      (!(lib.elem "dolphinrc" (hm none).programs.plasma.resetFilesExclude) && !((hm none).home.activation ? createDolphinPlaces))
      "a host without dolphin still has the dolphinrc exclusion, or the places activation, so the dolphin checks are vacuous";

    check-helium-chromium-assertion-fires = check (lib.length (failing xorMsg both) == 1)
      "helium and chromium enabled together must raise exactly one assertion, got ${toString (lib.length (failing xorMsg both))}";
    check-helium-alone-no-assertion = check (failing xorMsg heliumOnly == [ ])
      "helium without chromium raises the exclusion assertion";

    check-pwa-entries-plain-network = check (pwas != { } && pwaProblems pwas == [ ])
      "pwa desktop entries with mimeType or categories other than Network: ${show (pwaProblems pwas)}";
    check-control-pwa-lint-detects = check
      (pwaProblems { x = { mimeType = [ "x-scheme-handler/http" ]; categories = [ "Network" ]; }; y = { categories = [ "Network" "WebBrowser" ]; }; } != [ ])
      "the PWA lint does not flag a planted mimeType or extra category";

    check-control-no-pwa-entries-without-module = check (pwaEntries none == { })
      "pwa-* desktop entries exist without krit.programs.pwas, so the PWA check is vacuous: ${show (lib.attrNames (pwaEntries none))}";

    check-logid-restart-trigger = check (lib.elem (logidSrc logid) (logidTriggers logid))
      "systemd.services.logid.restartTriggers does not contain the logid.cfg source";
    check-logid-trigger-follows-config = check
      (toString (logidSrc only4) != toString (logidSrc logid) && lib.elem (logidSrc only4) (logidTriggers only4) && !(lib.elem (logidSrc logid) (logidTriggers only4)))
      "the restart trigger does not change with the logid.cfg content";
    check-logid-udev-rule-once = check (c548Count logid == 1 && c548Count only4 == 1)
      "c548 udev rule count: both mice ${toString (c548Count logid)}, one mouse ${toString (c548Count only4)}, expected 1 each";
    check-control-no-logid-service-without-module = check (!(none.systemd.services ? logid) && c548Count none == 0)
      "the logid service or its udev rule exists without krit.services.logitech";
    check-control-logid-udev-rule-absent-without-mice = check (c548Count noMice == 0)
      "c548 udev rule still present with both mice off (${toString (c548Count noMice)}), so the count check is vacuous";
  };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
