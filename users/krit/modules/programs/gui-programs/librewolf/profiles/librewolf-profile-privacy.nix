{
  delib,
  pkgs,
  addons,
  searchConfig,
  commonSettings,
  inputs,
  ...
}:
delib.module {
  name = "krit-librewolf";

  # 🌟 The fix: Everything HM-related goes inside home.always
  home.always =
    { myconfig, ... }:
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
        "browser.privatebrowsing.autostart" = false; # Enable disk writes for cookies

        # 🔒 BLOCKLISTS
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;

        # ⚠️ FIXING THE REGRESSION ⚠️

        # 1. Fix 2FA / Timezone Issues
        # We must disable BOTH RFP and FPP.
        # FPP (FingerprintingProtection) can still mess with extension time/state.
        "privacy.resistFingerprinting" = false;
        "privacy.fingerprintingProtection" = false; # <--- CHANGE TO FALSE
        "privacy.resistFingerprinting.letterboxing" = false;
        "webgl.disabled" = true;

        # 2. Fix Cookie/Login Persistence
        # FPI (Isolation) breaks the "Allow" list logic during redirects (SSO).
        # We must disable it to let 'account.proton.me' talk to 'mail.proton.me'.
        "privacy.firstparty.isolate" = false; # <--- CHANGE TO FALSE

        # 🔒 LIFETIME POLICY
        # 2 = Delete on close (unless allowed)
        "network.cookie.lifetimePolicy" = 2;

        # 🔒 SANITIZE LOGIC
        "privacy.sanitize.sanitizeOnShutdown" = true;

        # Protect Auth Data
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

        # UI
        "sidebar.main.tools" = [
          "history"
          "bookmarks"
        ];
        "browser.startup.page" = 1;
        "layout.spellcheckDefault" = 0;
        "browser.translations.enable" = false;
        "browser.download.manager.addToRecentDocs" = false;
      };
    };
}
