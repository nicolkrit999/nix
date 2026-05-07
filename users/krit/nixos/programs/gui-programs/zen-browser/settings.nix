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
        "zen.workspaces.continue-where-left-off" = false;
        "zen.view.compact.hide-tabbar" = true;
        "zen.urlbar.behavior" = "float";

        # Required for isEssential pins (in pins.nix) to display correctly.
        "zen.window-sync.enabled" = true;
        "zen.window-sync.sync-only-pinned-tabs" = true;

        "extensions.autoDisableScopes" = 0;

        # Startup: open kagi.com instead of Zen's new-tab rectangle.
        # page=1 → load homepage; page=0 blank, page=3 restore session.
        "browser.startup.page" = 1;
        "browser.startup.homepage" = "https://kagi.com";

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
