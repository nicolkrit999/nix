{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.keyboardShortcuts = [
    ];
  };
}
