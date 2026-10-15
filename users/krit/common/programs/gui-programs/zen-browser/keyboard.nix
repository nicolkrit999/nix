{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = {
    # Placeholder: extra shortcuts go here
    programs.zen-browser.profiles.default.keyboardShortcuts = [ ];
  };
}
