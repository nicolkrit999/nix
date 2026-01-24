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

    # Do NOT enable until your OIDC works; it commonly breaks IdPs
    # privacy-badger
  ];

  settings = commonSettings // {
    # Keep everything for daily use
    "privacy.sanitize.sanitizeOnShutdown" = false;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.downloads" = false;

    # Session restore
    "browser.startup.page" = 3;

    # Referrers permissive (OIDC)
    "network.http.referer.XOriginPolicy" = 0;
    "network.http.referer.XOriginTrimmingPolicy" = 0;

    # Don’t break local/self-hosted auth flows
    "dom.security.https_only_mode" = false;
    "dom.security.https_only_mode_ever_enabled" = false;

    # DRM
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # UI
    "sidebar.main.tools" = [
      "history"
      "bookmarks"
    ];
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "accessibility.typeaheadfind" = true;
  };
}
