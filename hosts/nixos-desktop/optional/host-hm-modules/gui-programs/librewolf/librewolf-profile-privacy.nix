{ pkgs, addons, searchConfig, commonSettings, vars, inputs, ... }:
{
  id = 1;
  name = "Privacy";
  isDefault = false;

  search = searchConfig;

  # 🧩 EXTENSIONS
  extensions.packages = with addons; [
    kagi-search
    privacy-badger
    proton-pass
    simplelogin

    # Other
    firefox-color
    ublock-origin

  ];

  # TODO: The extensions allowed remembers the account but the respective websites still ask to login again. Investigate.
  settings = commonSettings // {
    "sidebar.main.tools" = [ "history" "bookmarks" ];
    # Keep cookies and use sanitzie to allow custom cookie list
    "network.cookie.lifetimePolicy" = 0;
    "privacy.sanitize.sanitizeOnShutdown" = true;

    # What to DELETE on exit:
    "privacy.clearOnShutdown.history" = true;
    "privacy.clearOnShutdown.downloads" = true;
    "privacy.clearOnShutdown.cache" = true;
    "privacy.clearOnShutdown.formdata" = true;
    "places.history.enabled" = true;
    "privacy.clearOnShutdown.cookies" = true;

    # Keep false to allow custom allowed cookies list
    "privacy.clearOnShutdown.sessions" = false; # Needed to keep allowed logins
    "privacy.clearOnShutdown.siteSettings" = false;
    "privacy.clearOnShutdown.offlineApps" = false;
    "browser.privatebrowsing.autostart" = false;

    # 🚫 HARDENING (No DRM, Anti-Fingerprinting)
    "media.eme.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;

    # RFP (Keep this true, forcing Light Mode for maximum privacy in this profile)
    "privacy.resistFingerprinting" = true;
    "webgl.disabled" = true;

    # 🌐 STRICT DNS (Quad9 - Mode 3: Enforced)
    "network.trr.mode" = 3;
    "network.trr.uri" = "https://dns.quad9.net/dns-query";
    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.dns.disablePrefetch" = true;

    # DISABLE TRANSLATION & SPELLCHECK (Prevent leakage)
    "layout.spellcheckDefault" = 0;
    "browser.translations.enable" = false;
    "browser.translations.panelShown" = false;
    "browser.download.manager.addToRecentDocs" = false;

    # Other
    "privacy.resistFingerprinting.letterboxing" = true;
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;

    # URL Bar Suggestions
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.quickactions.enabled" = false; # Tough in the ui it seems active it works
    "browser.urlbar.suggest.weather" = false;
  };
}
