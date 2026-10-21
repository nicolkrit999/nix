{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying keyboardShortcuts.
delib.module {
  name = "krit.programs.zen-browser";

  home.ifEnabled = {
    programs.zen-browser.profiles.default.keyboardShortcuts = [
      {
        id = "zen-compact-mode-toggle";
        key = "m";
        modifiers = {
          alt = true;
          shift = true;
        };
      }
    ];
  };
}
