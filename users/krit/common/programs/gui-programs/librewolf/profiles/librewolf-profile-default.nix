{ addons
, searchConfig
, commonSettings
}:
{
  id = 0;
  name = "Default";

  search = searchConfig;

  extensions.packages = with addons; [
    ublock-origin # Popular ad and tracker blocker
    proton-pass # Proton Pass password manager integration
    firefox-color # Custom Firefox themes and color schemes. Needed for catppuccin
    sponsorblock # Skips sponsored segments in videos on platforms like YouTube
    gesturefy # Mouse gesture navigation for enhanced browsing
    privacy-badger # Tracker blocking extension by EFF
    screenshot-capture-annotate # Screenshot capturing and annotation tool (awesome screenshot)
    multi-account-containers # Isolates browsing activities into separate containers
    behind-the-overlay-revival # Bypass popup overlays on websites
    onetab # Save memory by converting tabs into a list
    simplelogin # Proton Mail's email alias manager
    kagi-search # Kagi search engine integration for private browsing
    new-tab-override # Customize the new tab page
    youtube-screenshot-button
  ];

  settings = commonSettings // {
    "privacy.resistFingerprinting" = false;
    "privacy.trackingprotection.allow_list.convenience.enabled" = true;

    "network.trr.excluded-domains" = "nicolkrit.ch,ts.net,lan,home.arpa,internal,localdomain";

    "security.webauth.webauthn" = true;
    "dom.webnotifications.enabled" = true;

    # LibreWolf sanitizes on shutdown by default
    "privacy.sanitize.sanitizeOnShutdown" = false;
    "browser.startup.page" = 3;

    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;
    "media.gmp-manager.updateEnabled" = true;

    # JetKVM needs WebRTC with all ICE interfaces
    "media.peerconnection.enabled" = true;

    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "accessibility.typeaheadfind" = false;
  };
}
