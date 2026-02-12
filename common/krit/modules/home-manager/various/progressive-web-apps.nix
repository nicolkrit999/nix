{ pkgs, lib, ... }:

let
  # ---------------------------------------------------------
  # 🛠️ HELPER FUNCTION
  # ---------------------------------------------------------
  makeBravePwa = name: url: icon: startupClass: {
    name = "pwa-${builtins.replaceStrings [" "] ["-"] (lib.toLower name)}";
    value = {
      name = name;
      genericName = "Web App";
      comment = "Launch ${name} as a PWA";

      exec = "${pkgs.brave}/bin/brave --app=\"${url}\" --password-store=gnome";

      icon = icon;

      settings = {
        StartupWMClass = startupClass;
      };

      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "x-scheme-handler/https" "x-scheme-handler/http" ];
    };
  };

  # Custom icons
  notionIconFile = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
    sha256 = "0q0i6cz44q0b54w0gm5lcndg8c7fi4bxavf1ylwr6v8nv22s2lhv";
  };

  appleMusicIconFile = pkgs.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Apple_Music_icon.svg";
    sha256 = "0lw10k2x25gnhjykllf0crkwff43a69i9pmsglmhnyhbsmx3qz71";
  };

in
{
  home.packages = [ pkgs.brave ];

  xdg.desktopEntries = builtins.listToAttrs [
    # Manual Apps
    (makeBravePwa "YouTube" "https://www.youtube.com" "youtube" "brave-www.youtube.com__-Default")
    (makeBravePwa "YouTube Music" "https://music.youtube.com/" "youtube-music" "brave-music.youtube.com__-Default")
    (makeBravePwa "Apple Music" "https://music.apple.com/ch/home?l=en" "${appleMusicIconFile}" "brave-music.apple.com__ch_home-Default")
    (makeBravePwa "Notion" "https://www.notion.so/" "${notionIconFile}" "brave-www.notion.so__-Default")

    # Self-Hosted / Home Lab
    (makeBravePwa "Dashboard-Glance" "https://glance.nicolkrit.ch/" "utilities-system-monitor" "brave-glance.nicolkrit.ch__-Default")
    (makeBravePwa "NAS" "https://nas.nicolkrit.ch" "network-server" "brave-nas.nicolkrit.ch__-Default")
    (makeBravePwa "Linkwarden" "https://linkwarden.nicolkrit.ch/dashboard" "emblem-favorite" "brave-linkwarden.nicolkrit.ch__dashboard-Default")
    (makeBravePwa "OwnCloud" "https://owncloud.nicolkrit.ch/" "folder-cloud" "brave-owncloud.nicolkrit.ch__-Default")

    # Cloud Services
    (makeBravePwa "Proton Mail" "https://mail.proton.me/u" "internet-mail" "brave-mail.proton.me__u-Default")
    (makeBravePwa "Proton Drive" "https://drive.proton.me/u/0/" "folder-remote" "brave-drive.proton.me__u_0_-Default")
    (makeBravePwa "Google Gemini" "https://gemini.google.com/app" "utilities-terminal" "brave-gemini.google.com__app-Default")
    (makeBravePwa "Nix Search" "https://search.nixos.org/packages" "system-search" "brave-search.nixos.org__packages-Default")
    (makeBravePwa "GitHub" "https://github.com/" "vcs-git" "brave-github.com__-Default")
    (makeBravePwa "Reddit" "https://www.reddit.com/" "internet-news-reader" "brave-www.reddit.com__-Default")
  ];
}
