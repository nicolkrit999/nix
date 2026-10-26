{ host }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  user = sys.config.myconfig.constants.user;
  withLw = on: extra: (sys.extendModules {
    modules = [{ myconfig.krit.programs.librewolf.enable = lib.mkOverride 10 on; }] ++ extra;
  }).config;

  hmOf = c: c.home-manager.users.${user};
  mutant = withLw true [
    {
      home-manager.users.${user} = {
        xdg.desktopEntries."librewolf-privacy".exec = lib.mkOverride 10 "librewolf -P Nope";
        home.file.".librewolf/librewolf.overrides.cfg".text = lib.mkOverride 10 "";
        stylix.targets.librewolf.profileNames = lib.mkOverride 10 [ "default" ];
        programs.librewolf = {
          policies.Cookies.Allow = [ "https://example.org" ];
          profiles = {
            privacy = {
              settings = {
                "webgl.disabled" = lib.mkOverride 10 false;
                "privacy.sanitize.sanitizeOnShutdown" = lib.mkOverride 10 false;
                "permissions.manager.defaultsUrl" = lib.mkOverride 10 "";
                "privacy.fingerprintingProtection.overrides" = lib.mkOverride 10 "";
                "privacy.clearOnShutdown.cookies" = lib.mkOverride 10 true;
                "network.cookie.lifetimePolicy" = lib.mkOverride 10 2;
              };
              search.default = lib.mkOverride 10 "kagi";
              extensions.packages = lib.mkOverride 10 [ ];
              id = lib.mkOverride 10 5;
            };
            default = {
              settings = {
                "privacy.sanitize.sanitizeOnShutdown" = lib.mkOverride 10 true;
                "network.trr.excluded-domains" = lib.mkOverride 10 "";
                "privacy.firstparty.isolate" = lib.mkOverride 10 true;
                "extensions.autoDisableScopes" = lib.mkOverride 10 15;
              };
              isDefault = lib.mkOverride 10 false;
              search.engines.wikipedia.metaData.hidden = lib.mkOverride 10 false;
            };
          };
        };
      };
      specialisation."secure-travel".configuration = {
        myconfig.programs.zen.browser.enable = lib.mkOverride 10 true;
        myconfig.krit.programs.pwas.enable = lib.mkOverride 10 true;
        home-manager.users.${user}.programs.librewolf.profiles.privacy.isDefault = lib.mkOverride 10 false;
      };
    }
  ];
  lw = withLw true [ ];
  off = withLw false [ ];

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";
  allOk = rs: let bad = builtins.filter (r: r != "ok") rs; in if bad == [ ] then "ok" else builtins.head bad;

  parseUserJs = text: lib.listToAttrs (lib.concatMap
    (l:
      let m = builtins.match ''user_pref\("([^"]+)", (.*)\);'' l;
      in lib.optional (m != null) (lib.nameValuePair (builtins.elemAt m 0) (builtins.fromJSON (builtins.elemAt m 1))))
    (lib.splitString "\n" text));

  iniDefaultName = text:
    let
      ls = lib.splitString "\n" text;
      idx = lib.lists.findFirstIndex (l: l == "Default=1") null ls;
    in
    if idx == null then "NONE" else lib.removePrefix "Name=" (builtins.elemAt ls (idx + 2));
  iniDefaultCount = text: builtins.length (builtins.filter (l: l == "Default=1") (lib.splitString "\n" text));

  checks = c:
    let
      hm = hmOf c;
      lwc = hm.programs.librewolf;
      cfgPath = lwc.configPath;
      profs = lwc.profiles;
      userJs = n: parseUserJs hm.home.file."${cfgPath}/${profs.${n}.path}/user.js".text;
      D = userJs "default";
      P = userJs "privacy";
      has = S: k: S ? ${k};
      allIs = S: kv: allOk (lib.mapAttrsToList (k: v: eq k (S.${k} or "<unset>") v) kv);
      absent = S: ks: allOk (map (k: yes "${k} must not be set" (!(has S k))) ks);
      absentPrefix = S: pre: yes "no ${pre}* prefs" (!(builtins.any (lib.hasPrefix pre) (builtins.attrNames S)));
      names = n: map (p: p.pname or p.name) profs.${n}.extensions.packages;
      engines = profs.default.search.engines;

      s = c.specialisation."secure-travel".configuration;
      shm = hmOf s;
      shmProfs = shm.programs.librewolf.profiles;
      stIni = shm.home.file."${shm.programs.librewolf.configPath}/profiles.ini".text;
      ini = hm.home.file."${cfgPath}/profiles.ini".text;

      deadDefault = [
        "privacy.trackingprotection.enabled"
        "privacy.trackingprotection.fingerprinting.enabled"
        "privacy.trackingprotection.cryptomining.enabled"
        "privacy.trackingprotection.socialtracking.enabled"
        "privacy.fingerprintingProtection"
        "network.cookie.cookieBehavior"
        "network.cookie.cookieBehavior.pbmode"
        "privacy.firstparty.isolate"
        "network.cookie.lifetimePolicy"
        "network.cookie.sameSite.laxByDefault"
        "network.cookie.sameSite.noneRequiresSecure"
        "network.http.referer.XOriginPolicy"
        "network.http.referer.XOriginTrimmingPolicy"
        "permissions.manager.defaultsUrl"
        "dom.disable_open_during_load"
        "security.webauth.u2f"
        "dom.credentialmanagement.enabled"
      ];

      marker = "nixcfg.librewolf.profile";
      cfgOverridden = [ "webgl.disabled" "permissions.manager.defaultsUrl" "network.captive-portal-service.enabled" "captivedetect.canonicalURL" ];
      ovrText = hm.home.file.".librewolf/librewolf.overrides.cfg".text or "";
      ovrBlock = n:
        let parts = lib.splitString "if (profile === ${builtins.toJSON n}) {\n" ovrText;
        in if builtins.length parts == 2 then builtins.head (lib.splitString "\n}" (builtins.elemAt parts 1)) else "<no block>";
      reasserts = S: n: k: lib.hasInfix "pref(${builtins.toJSON k}, ${builtins.toJSON (S.${k} or null)});" (ovrBlock n);
    in
    {
      "profiles: exactly default (id 0) and privacy (id 1)" = allOk [
        (eq "profile names" (builtins.attrNames profs) [ "default" "privacy" ])
        (eq "ids" [ profs.default.id profs.privacy.id ] [ 0 1 ])
        (eq "display names" [ profs.default.name profs.privacy.name ] [ "Default" "Privacy" ])
      ];
      "profiles.ini: Default is the single default profile" = allOk [
        (eq "Default=1 count" (iniDefaultCount ini) 1)
        (eq "default profile" (iniDefaultName ini) "Default")
      ];
      "no browser policies, stock package, no policyroot/MOZ_APP_DISTRIBUTION hack" = allOk [
        (eq "policies" lwc.policies { })
        (eq "package pname" lwc.package.pname "librewolf")
        (yes "no policyroot file" (!(builtins.any (lib.hasInfix "policyroot") (builtins.attrNames hm.home.file))))
        (yes "no MOZ_APP_DISTRIBUTION" (!(hm.home.sessionVariables ? MOZ_APP_DISTRIBUTION)))
      ];
      "stylix profileNames == HM profile names" =
        eq "stylix.targets.librewolf.profileNames" (lib.sort (a: b: a < b) hm.stylix.targets.librewolf.profileNames) (builtins.attrNames profs);
      "desktop entry launches the Privacy profile by its HM name" = allOk [
        (yes "entry exists" (hm.xdg.desktopEntries ? "librewolf-privacy"))
        (eq "exec" hm.xdg.desktopEntries."librewolf-privacy".exec "librewolf -P ${profs.privacy.name} --no-remote")
      ];

      "search: ddg default in both profiles, ddg + kagi only" = allOk (map
        (n:
          let sr = profs.${n}.search; in allOk [
            (eq "${n} default" sr.default "ddg")
            (eq "${n} privateDefault" sr.privateDefault "ddg")
            (eq "${n} order" sr.order [ "ddg" "kagi" ])
            (yes "${n} no perplexity/google engine" (!(sr.engines ? perplexity) && !(sr.engines ? google) && !(sr.engines ? Google)))
            (yes "${n} kagi alias @k" (sr.engines.kagi.definedAliases == [ "@k" ]))
            (eq "${n} ddg alias" (sr.engines.ddg.metaData.alias or "<unset>") "@d")
          ])
        [ "default" "privacy" ]);
      "search: wikipedia, mojeek, startpage hidden" = allOk (map
        (e: yes "${e} hidden" (engines.${e}.metaData.hidden or false))
        [ "wikipedia" "mojeek" "startpage" ]);

      "extensions: 14 in default, 6 in privacy, privacy subset of default" = allOk [
        (eq "default count" (builtins.length (names "default")) 14)
        (eq "privacy count" (builtins.length (names "privacy")) 6)
        (yes "privacy subset" (builtins.all (n: builtins.elem n (names "default")) (names "privacy")))
        (yes "names non-empty" (builtins.all (n: n != "") (names "default" ++ names "privacy")))
      ];

      "both: shared prefs (autoDisableScopes, FxA off, no password manager/autofill, no new-tab junk, strict, sidebar)" = allOk (map
        (S: allIs S {
          "extensions.autoDisableScopes" = 0;
          "identity.fxaccounts.enabled" = false;
          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.contentblocking.category" = "strict";
          "sidebar.main.tools" = "history,bookmarks";
          "network.trr.mode" = 2;
          "network.trr.uri" = "https://dns.quad9.net/dns-query";
          "privacy.resistFingerprinting" = false;
          "browser.startup.homepage" = "https://duckduckgo.com/";
        }) [ D P ]);

      "default: no exit wipe, restores session, LibreWolf sanitize default overridden" = allIs D {
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "browser.startup.page" = 3;
      };
      "default: DoH exclusions keep internal names resolving" =
        eq "excluded-domains" (D."network.trr.excluded-domains" or null) "nicolkrit.ch,ts.net,lan,home.arpa,internal,localdomain";
      "default: web-compat prefs (notifications, Widevine + updates, WebRTC, webauthn, convenience allow-list)" = allIs D {
        "dom.webnotifications.enabled" = true;
        "media.eme.enabled" = true;
        "media.gmp-widevinecdm.enabled" = true;
        "media.gmp-manager.updateEnabled" = true;
        "media.peerconnection.enabled" = true;
        "security.webauth.webauthn" = true;
        "privacy.trackingprotection.allow_list.convenience.enabled" = true;
      };
      "default: no dead/weakening overrides, no v1 or v2 clearOnShutdown, WebRTC ICE left at default" = allOk [
        (absent D deadDefault)
        (absentPrefix D "privacy.clearOnShutdown")
        (absent D [ "media.peerconnection.ice.default_address_only" "media.peerconnection.ice.no_host" "webgl.disabled" ])
      ];

      "privacy: fingerprinting (FPP with overrides, RFP off, WebGL off)" = allIs P {
        "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme,-CanvasImageExtractionPrompt";
        "privacy.resistFingerprinting" = false;
        "webgl.disabled" = true;
      };
      "privacy: WebRTC hides local IP, DRM off, HTTPS-Only, referrer trimming 2 / cross-origin 1" = allIs P {
        "media.peerconnection.ice.default_address_only" = true;
        "media.peerconnection.ice.no_host" = true;
        "media.eme.enabled" = false;
        "media.gmp-widevinecdm.enabled" = false;
        "dom.security.https_only_mode" = true;
        "network.http.referer.XOriginPolicy" = 1;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
      };
      "privacy: DoH mode 2 (captive portals), uri == custom_uri, ts.net excluded" = allOk [
        (eq "mode" (P."network.trr.mode" or null) 2)
        (eq "custom_uri == uri" (P."network.trr.custom_uri" or null) (P."network.trr.uri" or "<unset>"))
        (eq "excluded" (P."network.trr.excluded-domains" or null) "ts.net")
      ];
      "privacy: captive portal detection on, connectivity service not enabled" = allOk [
        (allIs P {
          "network.captive-portal-service.enabled" = true;
          "captivedetect.canonicalURL" = "http://firefox-portal-detection.com/generate_204";
        })
        (yes "connectivity-service stays off" (!(P."network.connectivity-service.enabled" or false)))
      ];
      "privacy: exit wipe via v2 prefs (history, cookies+storage, cache, form data, site settings)" = allIs P {
        "privacy.sanitize.sanitizeOnShutdown" = true;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
        "privacy.clearOnShutdown_v2.cache" = true;
        "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
        "privacy.clearOnShutdown_v2.formdata" = true;
        "privacy.clearOnShutdown_v2.siteSettings" = true;
      };
      "privacy: no dead v1 wipe prefs, lifetimePolicy, firstparty.isolate" = allOk [
        (absent P [ "network.cookie.lifetimePolicy" "privacy.firstparty.isolate" "network.dns.disablePrefetch" "browser.privatebrowsing.autostart" ])
        (yes "no v1 privacy.clearOnShutdown.*" (!(builtins.any (lib.hasPrefix "privacy.clearOnShutdown.") (builtins.attrNames P))))
      ];
      "privacy: allow-list wired via permissions.manager.defaultsUrl (file:// store path)" = allOk [
        (yes "file:// URL to the store" (lib.hasPrefix "file:///nix/store/" (P."permissions.manager.defaultsUrl" or "")))
        (yes "store name" (lib.hasSuffix "-librewolf-privacy-permissions" (P."permissions.manager.defaultsUrl" or "")))
      ];
      "overrides.cfg: per-profile marker block re-asserts the Privacy prefs mozilla.cfg pref() overrides, none leak into Default" = allOk ([
        (yes "reads the marker" (lib.hasInfix "getPref(${builtins.toJSON marker})" ovrText))
        (eq "markers" [ (D.${marker} or null) (P.${marker} or null) ] [ "default" "privacy" ])
      ]
      ++ map (k: yes "privacy block re-asserts ${k}" (reasserts P "privacy" k)) cfgOverridden
      ++ map (k: yes "default block leaves ${k} alone" (!(lib.hasInfix "pref(${builtins.toJSON k}," (ovrBlock "default")))) cfgOverridden);

      "secure-travel: Privacy is the default LibreWolf profile (HM + profiles.ini)" = allOk [
        (eq "privacy.isDefault" shmProfs.privacy.isDefault true)
        (eq "default.isDefault" shmProfs.default.isDefault false)
        (eq "Default=1 count" (iniDefaultCount stIni) 1)
        (eq "profiles.ini default" (iniDefaultName stIni) "Privacy")
      ];
      "secure-travel: Zen, PWAs, stock Firefox/Chromium/Helium off" = allOk (
        [ (eq "zen" s.myconfig.programs.zen.browser.enable false) ]
        ++ map (n: eq n s.myconfig.krit.programs.${n}.enable false) [ "pwas" "firefox" "chromium" "helium" ]
      );
      "secure-travel: GNOME pin points at the Privacy entry that exists, Zen pin gone" = allOk [
        (yes "pinned privacy" (builtins.elem "librewolf-privacy.desktop" s.myconfig.programs.gnome.pinnedApps))
        (yes "no zen pin" (!(builtins.elem "zen-beta.desktop" s.myconfig.programs.gnome.pinnedApps)))
        (yes "entry exists in spec HM" (shm.xdg.desktopEntries ? "librewolf-privacy"))
      ];
      "base (non-spec) default profile stays Default" = allOk [
        (eq "default.isDefault" profs.default.isDefault true)
        (eq "privacy.isDefault" profs.privacy.isDefault false)
      ];
    };

  good = checks lw;
  bad = checks mutant;
  mustFail = [
    "privacy: fingerprinting (FPP with overrides, RFP off, WebGL off)"
    "privacy: exit wipe via v2 prefs (history, cookies+storage, cache, form data, site settings)"
    "privacy: no dead v1 wipe prefs, lifetimePolicy, firstparty.isolate"
    "privacy: allow-list wired via permissions.manager.defaultsUrl (file:// store path)"
    "overrides.cfg: per-profile marker block re-asserts the Privacy prefs mozilla.cfg pref() overrides, none leak into Default"
    "default: no exit wipe, restores session, LibreWolf sanitize default overridden"
    "profiles: exactly default (id 0) and privacy (id 1)"
    "profiles.ini: Default is the single default profile"
    "base (non-spec) default profile stays Default"
    "stylix profileNames == HM profile names"
    "desktop entry launches the Privacy profile by its HM name"
    "search: ddg default in both profiles, ddg + kagi only"
    "search: wikipedia, mojeek, startpage hidden"
    "extensions: 14 in default, 6 in privacy, privacy subset of default"
    "both: shared prefs (autoDisableScopes, FxA off, no password manager/autofill, no new-tab junk, strict, sidebar)"
    "default: DoH exclusions keep internal names resolving"
    "default: no dead/weakening overrides, no v1 or v2 clearOnShutdown, WebRTC ICE left at default"
    "no browser policies, stock package, no policyroot/MOZ_APP_DISTRIBUTION hack"
    "secure-travel: Privacy is the default LibreWolf profile (HM + profiles.ini)"
    "secure-travel: Zen, PWAs, stock Firefox/Chromium/Helium off"
  ];
  offHm = hmOf off;
in
{
  results = good // {
    "control: disabled module generates no LibreWolf profiles" = allOk [
      (eq "librewolf.enable" offHm.programs.librewolf.enable false)
      (yes "no privacy user.js" (!(offHm.home.file ? ".librewolf/privacy/user.js")))
      (yes "enabled twin has it" ((hmOf lw).home.file ? ".librewolf/privacy/user.js"))
    ];
  } // lib.listToAttrs (map
    (n: lib.nameValuePair "control: mutant fails '${n}'"
      (if good.${n} != "ok" then "FAIL: control premise: '${n}' already fails on the real config"
      else if bad.${n} == "ok" then "FAIL: mutant still passes '${n}'" else "ok"))
    mustFail);
}
