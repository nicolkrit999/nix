{ delib, inputs, pkgs, lib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }:
    let
      # XPI builder. Identical to the one in librewolf-common.nix.
      # Using pkgs.callPackage (system pkgs, allowUnfree=true) instead of
      # inputs.firefox-addons.packages.${system} (rycee's own pkgs, no allowUnfree)
      # so unfree addons like onetab can be evaluated.
      buildFirefoxXpiAddon = lib.makeOverridable (
        { stdenv ? pkgs.stdenv
        , fetchurl ? pkgs.fetchurl
        , pname
        , version
        , addonId
        , url
        , sha256
        , meta
        , ...
        }:
        stdenv.mkDerivation {
          name = "${pname}-${version}";
          inherit meta;
          src = fetchurl { inherit url sha256; };
          preferLocalBuild = true;
          allowSubstitutes = true;
          passthru = { inherit addonId; };
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            install -v -m644 "$src" "$dst/${addonId}.xpi"
          '';
        }
      );

      addons = pkgs.callPackage inputs.firefox-addons {
        buildMozillaXpiAddon = buildFirefoxXpiAddon;
      };
    in
    {
      # ── Rycee (NUR) extensions ──────────────────────────────────────────────
      # Extensions matching the librewolf setup (default + privacy profiles).
      programs.zen-browser.profiles.default.extensions.packages = with addons; [
        ublock-origin # Ad/tracker blocker
        proton-pass # Proton Pass password manager
        firefox-color # Theme support (used by catppuccin)
        sponsorblock # Skip sponsored YouTube segments
        gesturefy # Mouse gestures
        privacy-badger # EFF tracker blocker
        screenshot-capture-annotate # Awesome Screenshot
        multi-account-containers # NOTE: Zen has built-in containers; redundant but kept for parity
        behind-the-overlay-revival # Bypass popup overlays
        onetab # Convert tabs to a list (unfree license; allowed via system pkgs)
        simplelogin # Email aliases
        kagi-search # Kagi search integration
        new-tab-override # Custom new tab page
        youtube-screenshot-button # Screenshot YouTube videos
      ];

      # ── Normal (policy-based) extensions ────────────────────────────────────
      # No policy-based extensions yet. To add: uncomment the block below.
      # programs.zen-browser.policies.ExtensionSettings = {
      #   "extension-id@example.com" = {
      #     install_url = "https://addons.mozilla.org/firefox/downloads/latest/slug/latest.xpi";
      #     installation_mode = "force_installed";
      #   };
      # };
    };
}
