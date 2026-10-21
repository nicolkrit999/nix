{ delib, pkgs, ... }:
delib.module {
  name = "krit.programs.zen-browser";

  home.ifEnabled = {
    programs.zen-browser.profiles.default.extensions.packages = with pkgs.firefox-addons; [
      vimium # vim like keybinds for browser
      ublock-origin # Ad/tracker blocker
      proton-pass # Proton Pass password manager
      sponsorblock # Skip sponsored YouTube segments
      gesturefy # Mouse gestures
      privacy-badger # EFF tracker blocker
      screenshot-capture-annotate # Awesome Screenshot
      behind-the-overlay-revival # Bypass popup overlays
      onetab # Convert tabs to a list (unfree license; allowed via system pkgs)
      simplelogin # Email aliases
      kagi-search # Allow kagi search in private window using same account
      youtube-screenshot-button # Screenshot YouTube videos
    ];
  };
}
