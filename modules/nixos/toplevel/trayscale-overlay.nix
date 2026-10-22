{ delib, lib, moduleSystem, ... }:
let
  # TEMPORARY: nixpkgs trayscale 0.19.0 requests IPN-bus bits (NotifyRateLimit,
  # NotifyInitialNetMap) that tailscaled >= 1.104 rejects with 400, so no UI shows.
  # Fixed upstream in v0.20.0 (tailscale.com v1.104.1). v0.21.0 is deliberately
  # avoided (purego GTK bindings need a PUREGOTK_LIB_FOLDER wrapper).
  # v0.20.0 dist.sh `install` expects a prebuilt ./trayscale, so only install-data is used.
  # Remove when nixpkgs trayscale >= 0.20.0 builds against tailscale >= 1.104.
  trayscaleOverlay = _final: prev: {
    trayscale =
      if !lib.versionOlder prev.trayscale.version "0.20.0" then prev.trayscale
      else
        prev.trayscale.overrideAttrs (_old: {
          version = "0.20.0";
          src = prev.fetchFromGitHub {
            owner = "DeedleFake";
            repo = "trayscale";
            tag = "v0.20.0";
            hash = "sha256-NoTmBuoYPzAUYRvUOFCrj0+dW3DJU9HfOEx+yShEeUk=";
          };
          postInstall = ''
            sh ./dist.sh install-data $out
            glib-compile-schemas $out/share/glib-2.0/schemas
          '';
          vendorHash = "sha256-LubAFZXUAF9bmm2tHy+EwJ4kgqhob2I4KTxCzHEDG1c=";
        });
  };
in
delib.module {
  name = "trayscale-overlay";

  nixos.always.nixpkgs.overlays = [ trayscaleOverlay ];
  home.always = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = [ trayscaleOverlay ];
  };
}
