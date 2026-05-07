{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser = {
      policies = {
        DisableAppUpdate = true;
        DisablePocket = true;
      };

      profiles.default.settings = {
        "zen.workspaces.continue-where-left-off" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.urlbar.behavior" = "float";

        # Required for isEssential pins (in pins.nix) to display correctly.
        "zen.window-sync.enabled" = true;
        "zen.window-sync.sync-only-pinned-tabs" = true;

        # Auto-enable extensions added via home-manager extensions.packages.
        # Without this, side-loaded XPIs are detected but kept disabled until
        # the user manually flips them on in about:addons after each rebuild.
        # Bitmask of scopes to auto-disable; 0 = none.
        "extensions.autoDisableScopes" = 0;
      };
    };
  };
}
