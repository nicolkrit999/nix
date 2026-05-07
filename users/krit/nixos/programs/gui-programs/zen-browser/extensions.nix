{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    # ── Rycee (NUR) extensions ────────────────────────────────────────────────
    programs.zen-browser.profiles.default.extensions.packages =
      let
        addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
      in
      with addons; [
        ublock-origin
        proton-pass
      ];

    # ── Normal (policy-based) extensions ─────────────────────────────────────
    # Uncomment and populate when needed:
    # programs.zen-browser.policies.ExtensionSettings = {
    #   "extension-id@example.com" = {
    #     install_url = "https://addons.mozilla.org/firefox/downloads/latest/slug/latest.xpi";
    #     installation_mode = "force_installed";
    #   };
    # };
  };
}
