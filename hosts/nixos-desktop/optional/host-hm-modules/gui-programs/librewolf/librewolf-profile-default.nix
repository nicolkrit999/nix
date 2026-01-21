{ pkgs, addons, searchConfig, commonSettings, vars, inputs, ... }:
let
  # Function to build unfree addons (needed for some specific extensions if not in flake)
  buildXpi = pkgs.lib.makeOverridable ({ stdenv ? pkgs.stdenv, fetchurl, pname
    , version, addonId, url, sha256, ... }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";
      src = fetchurl { inherit url sha256; };
      preferLocalBuild = true;
      allowSubstitutes = true;
      passthru = { inherit addonId; };
      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    });
in {
  id = 0;
  name = "Default";
  isDefault = true;

  search = searchConfig;

  # 🧩 EXTENSIONS
  # Common + Original Firefox.nix list
  extensions.packages = with addons; [
    # Pinned
    kagi-search
    privacy-badger
    proton-pass
    simplelogin

    # Other
    sponsorblock
    multi-account-containers
    gesturefy
    firefox-color
    ublock-origin # (Forced by policy, but good to list)
    new-tab-override

  ];

  settings = commonSettings // {
    # 🍪 PERSISTENCE (Keep cookies/history)
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.downloads" = false;
    "privacy.sanitize.sanitizeOnShutdown" = false;

    # 🔒 HTTPS-ONLY MODE
    "dom.security.https_only_mode" = false;
    "dom.security.https_only_mode_ever_enabled" = true;

    # 🎬 DRM (Netflix/Spotify)
    "media.eme.enabled" = true;
    "media.gmp-widevinecdm.visible" = true;
    "media.gmp-widevinecdm.enabled" = true;

    # 🌐 DNS (Quad9 - Mode 2: Preferred/Optimistic)
    # Uses Quad9 but falls back to system if it fails (prevents breakage)
    # Does NOT enforce HTTPS for DNS to ensure compatibility
    "network.trr.mode" = 2;
    "network.trr.uri" = "https://dns.quad9.net/dns-query";
    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.trr.bootstrapAddress" = "9.9.9.9";
    "network.trr.excluded-domains" = "localhost,local,lan,router";
    "browser.contentblocking.category" =
      "custom"; # Standart protection. Override librewolf "strict" default.
    "privacy.antitracking.enableWebcompat" =
      true; # Work only when the protection is not "strict"

    # Allow referers to make login possible in websites that redirect
    "network.http.referer.XOriginPolicy" = 0;
    "network.http.referer.XOriginTrimmingPolicy" = 0;
    "network.cookie.cookieBehavior" = 0;

    # Sidebar tools
    "sidebar.main.tools" = [ "history" "bookmarks" ];

    # Restore Session
    "browser.startup.page" = 3;

    # Allow fingerprinting to allow dark mode to work
    "privacy.resistFingerprinting" = false;

    # Enable user stylesheets
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Type to search
    "accessibility.typeaheadfind" = true;

    # Address bar
    "browser.urlbar.suggest.history" = true;
    "browser.urlbar.suggest.bookmark" = true;
    "browser.urlbar.suggest.openpage" = true;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.engines" = true;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.weather" = true;
    "browser.urlbar.quickactions.enabled" = false;

    # Picture-in-Picture
    "media.videocontrols.picture-in-picture.enable-when-switching-tabs" = true;

    # Tracking protection
    "privacy.trackingprotection.fingerprinting.enabled" =
      false; # REQUIRED for Cloudflare Auth
    "privacy.trackingprotection.cryptomining.enabled" = false;
    "privacy.trackingprotection.enabled" = false;
    "privacy.trackingprotection.socialtracking.enabled" = false;

  };
}
