{ pkgs, addons, searchConfig, commonSettings, vars, inputs, ... }: {
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
    "sidebar.main.tools" = [ "history" "bookmarks" ];

    # 2 = Accept for Session Only.
    # Cookies are deleted on exit UNLESS they are in the Global 'Allow' Policy.
    "network.cookie.lifetimePolicy" = 2;

    "browser.startup.page" = 1; # 1 = Home Page

    # SANITIZE SETTINGS
    "privacy.sanitize.sanitizeOnShutdown" = true;

    # What to keep true (allow custom cookies list):
    "privacy.clearOnShutdown.history" = true;
    "privacy.clearOnShutdown.downloads" = true;
    "privacy.clearOnShutdown.cache" = true;
    "privacy.clearOnShutdown.formdata" = true;
    "places.history.enabled" = true;
    "privacy.resistFingerprinting" = true;

    # What to keep false (allow custom cookies list):
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.sessions" = false;
    "privacy.clearOnShutdown.siteSettings" = false;
    "privacy.clearOnShutdown.offlineApps" = false;
    "browser.privatebrowsing.autostart" = false;

    # 🔒 HARDENING
    "browser.contentblocking.category" = "strict";

    # Disavle DRM (Netflix/Spotify)
    "media.eme.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;
    "webgl.disabled" = true;

    # 🌐 DNS (Quad9 - Mode 3: Enforced)
    "network.trr.mode" = 3;
    "network.trr.uri" = "https://dns.quad9.net/dns-query";
    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.dns.disablePrefetch" = true;

    # FINGERPRINTING PROTECTION
    "privacy.resistFingerprinting.letterboxing" = true;

    # HTTPS mode
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;

    # Referrers in Privacy Mode (Might break Cloudflare, but safe for privacy)
    # If Cloudflare fails in Privacy Profile, change these to 0.
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;

    # Url bar suggestions
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.quickactions.enabled" = false;
    "browser.urlbar.suggest.weather" = false;

    # Various
    "layout.spellcheckDefault" = 0;
    "browser.translations.enable" = false;
    "browser.translations.panelShown" = false;
    "browser.download.manager.addToRecentDocs" = false;

    # Tracking protection
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
  };
}
