{
  pkgs,
  addons,
  searchConfig,
  commonSettings,
  vars,
  inputs,
  ...
}:
{
  id = 1;
  name = "Privacy";
  isDefault = false;
  search = searchConfig;

  extensions.packages = with addons; [
    kagi-search
    privacy-badger
    proton-pass
    simplelogin
    firefox-color
    ublock-origin
  ];

  settings = commonSettings // {
    # 🔒 PRIVACY MODE (Strict)
    "browser.contentblocking.category" = "strict";

    # 🔒 ENABLE ALL BLOCKLISTS
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;

    # 🔒 RE-ENABLE FPP
    "privacy.fingerprintingProtection" = true;

    # 🔒 ANTI-FINGERPRINTING (Forces Light Mode)
    "privacy.resistFingerprinting" = true;
    "privacy.resistFingerprinting.letterboxing" = true;
    "webgl.disabled" = true;

    # 🔒 COOKIE DELETION LOGIC
    # 2 = Accept for Session Only (Deleted on exit unless in Allow List)
    "network.cookie.lifetimePolicy" = 2;
    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.clearOnShutdown.history" = true;
    "privacy.clearOnShutdown.downloads" = true;
    "privacy.clearOnShutdown.cache" = true;
    "privacy.clearOnShutdown.formdata" = true;
    "privacy.clearOnShutdown.cookies" = true;
    "privacy.clearOnShutdown.sessions" = false;
    "privacy.clearOnShutdown.siteSettings" = false;
    "privacy.clearOnShutdown.offlineApps" = false;

    # HARDENING
    "media.eme.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;

    # REFERRERS (Strict)
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;

    # DNS (Enforced)
    "network.trr.mode" = 3;
    "network.trr.uri" = "https://dns.quad9.net/dns-query";
    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.dns.disablePrefetch" = true;

    # UI CLEANUP
    "sidebar.main.tools" = [
      "history"
      "bookmarks"
    ];
    "browser.startup.page" = 1; # Home Page
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.quickactions.enabled" = false;
    "browser.urlbar.suggest.weather" = false;
    "layout.spellcheckDefault" = 0;
    "browser.translations.enable" = false;
    "browser.download.manager.addToRecentDocs" = false;
  };
}
