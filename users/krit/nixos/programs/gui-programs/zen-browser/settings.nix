{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser = {
      policies = {
        DisablePocket = true;
        # Proton Pass handles credentials — kill Firefox's manager entirely.
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
      };

      profiles.default.settings = {
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.enable-at-startup" = false;
        "zen.urlbar.behavior" = "float";

        # Required for isEssential pins (in pins.nix) to display correctly.
        "zen.window-sync.enabled" = true;
        "zen.window-sync.sync-only-pinned-tabs" = true;

        "extensions.autoDisableScopes" = 0;

        # Don't restore session after pkill/crash — that overrides startup page.
        "browser.sessionstore.resume_from_crash" = false;

        # Disable built-in password manager — Proton Pass handles credentials.
        # rememberSignons=false suppresses the save-password prompt entirely.
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "signon.generation.enabled" = false;
        "signon.management.page.breach-alerts.enabled" = false;
      };
    };
  };
}
