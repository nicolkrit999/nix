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
  id = 0;
  name = "Default";
  isDefault = true;

  search = searchConfig;

  extensions.packages = with addons; [
    kagi-search
    proton-pass
    simplelogin
    sponsorblock
    multi-account-containers
    gesturefy
    firefox-color
    ublock-origin
    new-tab-override

    privacy-badger # If it give problems for auth, disable it
  ];

  settings = commonSettings // {

    # Disable heavy privacy features that break sites/auth
    "privacy.resistFingerprinting" = false;
    "privacy.fingerprintingProtection" = false;
    "privacy.trackingprotection.enabled" = false;
    "privacy.trackingprotection.fingerprinting.enabled" = false;
    "privacy.trackingprotection.socialtracking.enabled" = false;
    "privacy.trackingprotection.cryptomining.enabled" = false;

    # Cookies & Isolation
    "privacy.firstparty.isolate" = false;
    "network.cookie.cookieBehavior" = 0; # Accept all cookies
    "network.cookie.cookieBehavior.pbmode" = 0;
    "network.cookie.lifetimePolicy" = 0; # Keep cookies normally

    # Cross site behaviour to allow authentication flows
    "network.cookie.sameSite.laxByDefault" = false;
    "network.cookie.sameSite.noneRequiresSecure" = false;

    # Permissive referrers to allow authentication flows
    "network.http.referer.XOriginPolicy" = 0;
    "network.http.referer.XOriginTrimmingPolicy" = 0;

    # DNS
    "network.trr.mode" = 5;

    # -------------------------------------------------------------------------
    # 🔑 AUTHENTICATION & CREDENTIALS
    # -------------------------------------------------------------------------

    # Fixed WebAuthn/U2F support for authentication domains
    "security.webauth.webauthn" = true;
    "security.webauth.u2f" = true;
    "dom.credentialmanagement.enabled" = true;
    "dom.security.https_only_mode" = false;

    # Allow popups and background services for authentication domains
    "dom.serviceWorkers.enabled" = true;
    "dom.webnotifications.enabled" = true;

    # Enable FxA (allow authentication providers)
    "identity.fxaccounts.enabled" = true;

    # -------------------------------------------------------------------------
    # 🧹 GENERAL
    # -------------------------------------------------------------------------

    # Keep everything for daily use
    "privacy.sanitize.sanitizeOnShutdown" = false;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.downloads" = false;

    # Session restore
    "browser.startup.page" = 3;

    # DRM
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # JetKVM tweaks
    "media.peerconnection.enabled" = true;
    "media.webrtc.hw.h264.enabled" = true;

    # UI
    "sidebar.main.tools" = [
      "history"
      "bookmarks"
    ];
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "accessibility.typeaheadfind" = true;
  };
}
