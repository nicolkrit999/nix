let
  host = builtins.getEnv "HOST_UNDER_TEST";
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.${host};
  cfg = sys.config;
  user = cfg.myconfig.constants.user;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  mk = lib.mkForce;
  twin = modules: (sys.extendModules { inherit modules; }).config;
  hm = c: c.home-manager.users.${user};
  show = builtins.toJSON;

  mice = { mx3s, mx4 }: {
    myconfig.krit.services.logitech = {
      enable = mk true;
      mouses.mx-master-3s.enable = mk mx3s;
      mouses.mx-master-4.enable = mk mx4;
    };
  };
  programs = { chromium }: {
    myconfig.krit.programs = {
      dolphin.enable = mk true;
      pwas.enable = mk true;
      helium.enable = mk true;
      chromium.enable = mk chromium;
    };
  };

  a = twin [ (programs { chromium = false; }) (mice { mx3s = true; mx4 = true; }) ];
  both = twin [ (programs { chromium = true; }) (mice { mx3s = true; mx4 = true; }) ];
  only4 = twin [ (programs { chromium = false; }) (mice { mx3s = false; mx4 = true; }) ];
  noMice = twin [ (programs { chromium = false; }) (mice { mx3s = false; mx4 = false; }) ];

  failing = needle: c: lib.filter (x: lib.hasInfix needle x.message) (lib.filter (x: !x.assertion) c.assertions);
  xorMsg = "krit.programs.helium and krit.programs.chromium are mutually exclusive";

  pkgNames = c: map lib.getName (c.environment.systemPackages ++ (hm c).home.packages);
  count = n: c: lib.length (lib.filter (x: x == n) (pkgNames c));
  dolphinrc = (hm a).xdg.configFile."dolphinrc".text;
  pluginsLines = text: lib.filter (l: lib.hasPrefix "Plugins=" (lib.trim l)) (lib.splitString "\n" text);
  places = (hm a).home.activation.createDolphinPlaces.data;
  homeDir = (hm a).home.homeDirectory;

  pwas = lib.filterAttrs (n: _: lib.hasPrefix "pwa-" n) (hm a).xdg.desktopEntries;
  pwaProblems = entries: lib.concatLists (lib.mapAttrsToList
    (n: e:
      lib.optional ((e.mimeType or [ ]) != [ ] && (e.mimeType or null) != null) "${n}: mimeType ${show e.mimeType}"
      ++ lib.optional ((e.categories or [ ]) != [ "Network" ]) "${n}: categories ${show (e.categories or [ ])}")
    entries);

  rcloneDefs = sys.options.myconfig.services.rcloneMount.enable.definitionsWithLocations;
  cloudDefs = lib.filter (d: lib.hasInfix "/services/cloud/" (toString d.file)) rcloneDefs;
  cloudMods = cfg.myconfig.krit.services.cloud;
  cloudEnabled = lib.filter (n: cloudMods.${n}.enable) (lib.attrNames cloudMods);

  c548 = "ATTR{idProduct}==\"c548\"";
  c548Count = c: lib.length (lib.splitString c548 c.services.udev.extraRules) - 1;
  logidTriggers = c: c.systemd.services.logid.restartTriggers;
  logidSrc = c: c.environment.etc."logid.cfg".source;

  checks = {
    check-dolphin-resets-exclude-dolphinrc = check (lib.elem "dolphinrc" (hm a).programs.plasma.resetFilesExclude)
      "programs.plasma.resetFilesExclude is ${show (hm a).programs.plasma.resetFilesExclude}, lacks dolphinrc";
    check-dolphinrc-no-plugins-line = check (pluginsLines dolphinrc == [ ] && lib.hasInfix "[General]" dolphinrc)
      "dolphinrc has Plugins= lines (the hand-written plugin list hides new thumbnailers): ${show (pluginsLines dolphinrc)}";
    check-dolphin-thumbnailers-installed = check
      (lib.elem "kdegraphics-thumbnailers" (pkgNames a) && lib.elem "ffmpegthumbs" (pkgNames a))
      "kdegraphics-thumbnailers / ffmpegthumbs missing from the packages";
    check-dolphin-installed-at-most-once = check (count "dolphin" a <= 1)
      "dolphin installed ${toString (count "dolphin" a)} times (dolphin.nix must not add kdePackages.dolphin)";
    check-dolphin-places-momentary-and-mnt = check
      (lib.all (p: lib.hasInfix "href=\"file://${p}\"" places) [ "${homeDir}/momentary" "/mnt" ]
        && lib.hasInfix "<title>momentary</title>" places && lib.hasInfix "grep -qF 'href=\"file:///mnt\"'" places)
      "createDolphinPlaces lacks the momentary or /mnt bookmark (seed and append-if-missing paths)";
    check-control-plugins-line-detected = check (pluginsLines "[General]\nPlugins=a,b\n" == [ "Plugins=a,b" ])
      "the Plugins= lint does not flag a planted line";

    check-helium-chromium-assertion-fires = check (lib.length (failing xorMsg both) == 1)
      "helium and chromium enabled together must raise exactly one assertion, got ${toString (lib.length (failing xorMsg both))}";
    check-helium-alone-no-assertion = check (failing xorMsg a == [ ])
      "helium without chromium raises the exclusion assertion";

    check-pwa-entries-plain-network = check (pwas != { } && pwaProblems pwas == [ ])
      "pwa desktop entries with mimeType or categories other than Network: ${show (pwaProblems pwas)}";
    check-control-pwa-lint-detects = check
      (pwaProblems { x = { mimeType = [ "x-scheme-handler/http" ]; categories = [ "Network" ]; }; y = { categories = [ "Network" "WebBrowser" ]; }; } != [ ])
      "the PWA lint does not flag a planted mimeType or extra category";

    check-cloud-modules-enable-rclone-mount = check
      (cloudEnabled != [ ] && lib.length cloudDefs == lib.length cloudEnabled && lib.all (d: d.value == true) cloudDefs)
      "rcloneMount.enable definitions from services/cloud modules: ${show (map (d: toString d.file) cloudDefs)}, enabled cloud modules: ${show cloudEnabled}";

    check-logid-restart-trigger = check (lib.elem (logidSrc a) (logidTriggers a))
      "systemd.services.logid.restartTriggers does not contain the logid.cfg source";
    check-logid-trigger-follows-config = check
      (toString (logidSrc only4) != toString (logidSrc a) && lib.elem (logidSrc only4) (logidTriggers only4) && !(lib.elem (logidSrc a) (logidTriggers only4)))
      "the restart trigger does not change with the logid.cfg content";
    check-logid-udev-rule-once = check (c548Count a == 1 && c548Count only4 == 1)
      "c548 udev rule count: both mice ${toString (c548Count a)}, one mouse ${toString (c548Count only4)}, expected 1 each";
    check-control-logid-udev-rule-absent-without-mice = check (c548Count noMice == 0)
      "c548 udev rule still present with both mice off (${toString (c548Count noMice)}), so the count check is vacuous";
  };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
