{
  addons,
  searchConfig,
  commonSettings,
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
    # 🔒 PRIVACY MODE
    "browser.contentblocking.category" = "strict";
    "browser.privatebrowsing.autostart" = false;

    # 🔒 BLOCKLISTS
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;

    # ⚠️ FIXING THE REGRESSION ⚠️
    "privacy.resistFingerprinting" = false;
    "privacy.fingerprintingProtection" = false;
    "privacy.resistFingerprinting.letterboxing" = false;
    "webgl.disabled" = true;

    # Solve Cookie/Login Persistence
    "privacy.firstparty.isolate" = false;

    # 🔒 LIFETIME POLICY
    "network.cookie.lifetimePolicy" = 2;

    # 🔒 SANITIZE LOGIC
    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.offlineApps" = false;
    "privacy.clearOnShutdown.siteSettings" = false;

    # Wipe the rest
    "privacy.clearOnShutdown.history" = true;
    "privacy.clearOnShutdown.downloads" = true;
    "privacy.clearOnShutdown.cache" = true;
    "privacy.clearOnShutdown.formdata" = true;
    "privacy.clearOnShutdown.sessions" = true;
    "privacy.clearOnShutdown.openWindows" = false;

    # HARDENING
    "media.eme.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_ever_enabled" = true;

    # REFERRERS
    "network.http.referer.XOriginPolicy" = 2;
    "network.http.referer.XOriginTrimmingPolicy" = 2;

    # DNS
    "network.trr.mode" = 3;
    "network.trr.uri" = "https://dns.quad9.net/dns-query";
    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.dns.disablePrefetch" = true;
  };
}
