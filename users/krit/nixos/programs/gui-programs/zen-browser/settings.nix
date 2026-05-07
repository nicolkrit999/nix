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

        # Reset to auto-detect — lets the Wayland compositor (via MOZ_ENABLE_WAYLAND)
        # supply the correct fractional scale. Clears any stale hardcoded value in prefs.js.
        "layout.css.devPixelsPerPx" = "-1";

        "browser.uiCustomization.state" = builtins.toJSON {
          placements = {
            widget-overflow-fixed-list = [ ];
            unified-extensions-area = [
              "sponsorblocker_ajay_app-browser-action"
              "ublock0_raymondhill_net-browser-action"
              "jid0-gxjllfbcoax0lcltedfrekqdqpi_jetpack-browser-action"
              "firefoxcolor_mozilla_com-browser-action"
              "_506e023c-7f2b-40a3-8066-bc5deb40aebe_-browser-action"
              "search_kagi_com-browser-action"
              "_d8b32864-153d-47fb-93ea-c273c4d1ef17_-browser-action"
            ];
            nav-bar = [
              "back-button"
              "forward-button"
              "stop-reload-button"
              "customizableui-special-spring1"
              "vertical-spacer"
              "urlbar-container"
              "customizableui-special-spring2"
              "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
              "extension_one-tab_com-browser-action"
              "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action"
              "unified-extensions-button"
              "78272b6fa58f4a1abaac99321d503a20_proton_me-browser-action"
              "addon_simplelogin-browser-action"
            ];
            toolbar-menubar = [ "menubar-items" ];
            TabsToolbar = [ "tabbrowser-tabs" ];
            vertical-tabs = [ ];
            PersonalToolbar = [ "import-button" "personal-bookmarks" ];
            zen-sidebar-top-buttons = [ "zen-toggle-compact-mode" ];
            zen-sidebar-foot-buttons = [
              "downloads-button"
              "zen-workspaces-button"
              "zen-create-new-button"
            ];
          };
          currentVersion = 23;
        };
      };
    };
  };
}
