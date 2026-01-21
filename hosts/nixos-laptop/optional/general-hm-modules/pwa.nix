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
    url =
      "https://upload.wikimedia.org/wikipedia/commons/4/45/Notion_app_logo.png";
    sha256 = "1gnm4ib1i30winhz4qhpyx21syp9ahhwdj3n1l7345l9kmjiv06s";
  };

  appleMusicIcon = pkgs.fetchurl {
    url =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Apple_Music_icon.svg/1024px-Apple_Music_icon.svg.png";
    sha256 = "039c0xxwjvh4gfjnhfyrdc3kk09q3glvd7m8zsg9nzdg01bybkx7";
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
