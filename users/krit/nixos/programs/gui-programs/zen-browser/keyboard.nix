{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Keyboard shortcuts write to zen-keyboard-shortcuts.json; Zen reads it on
# startup and won't pick up changes until restart. The version-mismatch check
# may also fail the build if Zen has rewritten the file while running.
#
# Host-specific keyboard shortcuts.
# Global shortcut (zen-compact-mode-toggle → Ctrl+Alt+C) is in the global module.
# Find shortcut IDs: jq -c '.shortcuts[] | {id, key, keycode, action}' \
#   ~/.config/zen/default/zen-keyboard-shortcuts.json | fzf
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.keyboardShortcuts = [
      # Add host-specific shortcuts here, e.g.:
      # { id = "key_quitApplication"; disabled = true; }
    ];
  };
}
