{ pkgs, lib, vars, ... }:
let
  # 1. Detect Architecture
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  # pwa that needs different browsers based on architecture
  pwaBrowser = "${pkgs.brave}/bin/brave";

  # Regular pwa
  browserPkg = pkgs.${vars.browser};
  browserBin = "${browserPkg}/bin/${vars.browser}";

  appleMusicCommand = if isX86 then
    ''${pkgs.brave}/bin/brave --app="https://music.apple.com/ch/home?l=en"''
  else
    ''
      ${pkgs.firefox}/bin/firefox --new-window "https://music.apple.com/ch/home?l=en"'';

  # Detect firefox-based browsers
  isFirefox = vars.browser == "firefox" || vars.browser == "librewolf"
    || vars.browser == "floorp";

  notionIcon = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    sha256 = "0q0i6cz44q0b54w0gm5lcndg8c7fi4bxavf1ylwr6v8nv22s2lhv";
  };

  appleMusicIcon = pkgs.fetchurl {
    url =
      "https://upload.wikimedia.org/wikipedia/commons/5/5f/Apple_Music_icon.svg";
    sha256 = "0lw10k2x25gnhjykllf0crkwff43a69i9pmsglmhnyhbsmx3qz71";
  };

  mkWebApp = name: url: icon: {
    inherit name icon;
    genericName = "Web Application";
    # Logic: If Firefox, use --new-window. If Chromium-based, use --app=URL for true "App Mode".
    exec = if isFirefox then
      "${browserBin} --new-window ${url}"
    else
      "${browserBin} --app=${url}";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
    type = "Application";
  };
in {
  xdg.desktopEntries = {

    # Direcly from the links
    dashboard = mkWebApp "Dashboard-Glance-PWA" "https://glance.nicolkrit.ch/"
      "utilities-system-monitor";

    nas = mkWebApp "NAS-PWA" "https://nas.nicolkrit.ch" "network-server";

    linkwarden =
      mkWebApp "Linkwarden-PWA" "https://linkwarden.nicolkrit.ch/dashboard"
      "emblem-favorite";

    nix-search = mkWebApp "Nix Search-PWA" "https://search.nixos.org/packages"
      "system-search";

    proton-mail =
      mkWebApp "Proton Mail-PWA" "https://mail.proton.me/u" "internet-mail";

    owncloud =
      mkWebApp "OwnCloud-PWA" "https://owncloud.nicolkrit.ch/" "folder-cloud";

    google-gemini =
      mkWebApp "Google Gemini AI-PWA" "https://gemini.google.com/app"
      "utilities-terminal";

    github = mkWebApp "Github-PWA" "https://github.com/" "vcs-git";

    proton-drive = mkWebApp "Proton Drive-PWA" "https://drive.proton.me/u/0/"
      "drive-harddisk";

    reddit =
      mkWebApp "Reddit-PWA" "https://www.reddit.com/" "internet-news-reader";

    # Manual pwa
    # Notion
    notion = {
      name = "Notion-PWA";
      genericName = "Notes";
      exec = "${pwaBrowser} --app=https://www.notion.so/ --class=notion";
      terminal = false;
      icon = notionIcon;
      settings = { StartupWMClass = "notion"; };
      categories = [ "Office" "Utility" ];
    };

    # --- Apple Music (Smart Switch) ---
    apple-music = {
      name = "Apple Music-PWA";
      genericName = "Music Player";
      exec = appleMusicCommand;
      terminal = false;
      icon = appleMusicIcon;
      settings = {
        StartupWMClass = if isX86 then "apple-music" else "firefox";
      };
      categories = [ "AudioVideo" "Audio" ];
    };
  };
}
