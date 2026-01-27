{
  pkgs,
  lib,
  ...
}:
let
  browserBin = "${pkgs.vivaldi}/bin/vivaldi";

  # 🎨 ICONS
  notionIcon = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    sha256 = "0q0i6cz44q0b54w0gm5lcndg8c7fi4bxavf1ylwr6v8nv22s2lhv";
  };
  appleMusicIcon = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Apple_Music_icon.svg";
    sha256 = "0lw10k2x25gnhjykllf0crkwff43a69i9pmsglmhnyhbsmx3qz71";
  };

  # 🛠️ GENERATOR FUNCTION
  mkWebApp = name: url: icon: {
    inherit name icon;
    genericName = "Web Application";
    exec = "${browserBin} --app=${url}";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    type = "Application";
  };
in
{
  xdg.desktopEntries = {

    # ---------------------------------------------------------
    # 🔗 SIMPLE LINKS
    # ---------------------------------------------------------
    dashboard =
      mkWebApp "Dashboard-Glance-PWA" "https://glance.nicolkrit.ch/"
        "utilities-system-monitor";

    nas = mkWebApp "NAS-PWA" "https://nas.nicolkrit.ch" "network-server";

    linkwarden =
      mkWebApp "Linkwarden-PWA" "https://linkwarden.nicolkrit.ch/dashboard"
        "emblem-favorite";

    nix-search = mkWebApp "Nix Search-PWA" "https://search.nixos.org/packages" "system-search";

    proton-mail = mkWebApp "Proton Mail-PWA" "https://mail.proton.me/u" "internet-mail";

    owncloud = mkWebApp "OwnCloud-PWA" "https://owncloud.nicolkrit.ch/" "folder-cloud";

    google-gemini =
      mkWebApp "Google Gemini AI-PWA" "https://gemini.google.com/app"
        "utilities-terminal";

    github = mkWebApp "Github-PWA" "https://github.com/" "vcs-git";

    proton-drive = mkWebApp "Proton Drive-PWA" "https://drive.proton.me/u/0/" "drive-harddisk";

    reddit = mkWebApp "Reddit-PWA" "https://www.reddit.com/" "internet-news-reader";

    # ---------------------------------------------------------
    # 📝 MANUAL APPS
    # ---------------------------------------------------------
    # Notion
    notion = {
      name = "Notion-PWA";
      genericName = "Notes";
      exec = "${browserBin} --app=https://www.notion.so/ --class=notion";
      terminal = false;
      icon = notionIcon;
      settings = {
        StartupWMClass = "notion";
      };
      categories = [
        "Office"
        "Utility"
      ];
    };

    # YouTube
    youtube-pwa = {
      name = "YouTube-PWA";
      genericName = "Video Player";

      exec = "${browserBin} --app=https://www.youtube.com --class=vivaldi-www.youtube.com";

      terminal = false;
      icon = "youtube";
      settings = {
        StartupWMClass = "vivaldi-www.youtube.com";
      };
      categories = [
        "AudioVideo"
        "Video"
        "Network"
      ];
    };

    # Apple Music
    apple-music = {
      name = "Apple Music-PWA";
      genericName = "Music Player";
      exec = "${browserBin} --app=\"https://music.apple.com/ch/home?l=en\"";
      terminal = false;
      icon = appleMusicIcon;
      settings = {
        StartupWMClass = "music.apple.com";
      };
      categories = [
        "AudioVideo"
        "Audio"
      ];
    };
  };
}
