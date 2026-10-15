{ pkgs
, lib
, addons
, searchConfig
, commonSettings
}:
let
  # Origins keeping their data across the shutdown wipe, plus Gecko's built-in default permissions
  # (a defaultsUrl file replaces them). Fields are tab-separated.
  # LibreWolf blanks defaultsUrl to drop these Mozilla-domain grants; re-granting them here is accepted.
  keepOrigins = [
    "https://nicolkrit.ch"
    "https://nicolkrit.cloudflareaccess.com"
    "https://kagi.com"
    "https://proton.me"
    "https://protonmail.com"
    "https://protonmail.ch"
    "https://simplelogin.io"
    "https://simplelogin.com"
  ];
  builtinPermissions = [
    "uitour\t1\thttps://www.mozilla.org"
    "uitour\t1\thttps://support.mozilla.org"
    "uitour\t1\tabout:home"
    "uitour\t1\tabout:newtab"
    "uitour\t1\thttps://www.firefox.com"
    "install\t1\thttps://addons.mozilla.org"
    "remote-troubleshooting\t1\thttps://support.mozilla.org"
    "autoplay-media\t1\tabout:welcome"
  ];
  privacyPerms = pkgs.writeText "librewolf-privacy-permissions" (
    lib.concatMapStrings (line: "origin\t${line}\n") (
      (map (origin: "persist-data-on-shutdown\t1\t${origin}") keepOrigins) ++ builtinPermissions
    )
  );
in
{
  id = 1;
  name = "Privacy";
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
    "privacy.resistFingerprinting" = false;
    "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme,-CanvasImageExtractionPrompt";
    "webgl.disabled" = true;

    "media.peerconnection.ice.default_address_only" = true;
    "media.peerconnection.ice.no_host" = true;

    "media.eme.enabled" = false;
    "media.gmp-widevinecdm.enabled" = false;
    "dom.security.https_only_mode" = true;

    "network.http.referer.XOriginPolicy" = 1;
    "network.http.referer.XOriginTrimmingPolicy" = 2;

    "network.trr.custom_uri" = "https://dns.quad9.net/dns-query";
    "network.trr.excluded-domains" = "ts.net";

    "network.captive-portal-service.enabled" = true;
    "captivedetect.canonicalURL" = "http://firefox-portal-detection.com/generate_204";

    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
    "privacy.clearOnShutdown_v2.cache" = true;
    "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
    "privacy.clearOnShutdown_v2.formdata" = true;
    "privacy.clearOnShutdown_v2.siteSettings" = true;
    "permissions.manager.defaultsUrl" = "file://${privacyPerms}";
  };
}
