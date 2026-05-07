{ delib
, inputs
, moduleSystem
, lib
, ...
}:
delib.module {
  name = "programs.zen.browser";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [ inputs.zen-browser.homeModules.beta ];
  };

  nixos.ifEnabled = { ... }: {
    myconfig.stylix.targets."zen-browser".profileNames = [ "default" ];
  };

  home.ifEnabled = { ... }: {
    # Force native Wayland rendering so extension popups render at the correct
    # fractional scale. Without this, Zen falls back to XWayland on all compositors,
    # which either upscales or downscales popups → blurry / wrong size.
    # Safe on X11 (gracefully falls back if WAYLAND_DISPLAY is unset).
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";

    programs.zen-browser = {
      enable = true;
      setAsDefaultBrowser = false;

      policies = {
        DisableTelemetry = true;
        DisableAppUpdate = true;
        DontCheckDefaultBrowser = true;
      };

      profiles.default = {
        # ⚠ CLOSE ZEN BEFORE REBUILD when modifying keyboardShortcuts*.
        # Writes to zen-keyboard-shortcuts.json; Zen won't pick up changes
        # until restart, and the version-check may fail if Zen rewrote the file.
        keyboardShortcutsVersion = lib.mkDefault 17;
        keyboardShortcuts = [
          {
            id = "zen-compact-mode-toggle";
            # Ctrl+Alt+C: swallowed by US-International keymap (Ctrl+Alt = AltGr).
            # Ctrl+Shift+M: collides with Firefox Responsive Design Mode.
            # Alt+Shift+M: clean — no AltGr, no Firefox built-in.
            key = "m";
            modifiers = {
              alt = true;
              shift = true;
            };
          }
        ];
      };
    } // lib.optionalAttrs (moduleSystem == "darwin") {
      darwinDefaultsId = "app.zen-browser.zen";
    };
  };
}
