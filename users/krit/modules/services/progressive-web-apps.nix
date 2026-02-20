{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "krit.programs.pwas";
  options.krit.programs.pwas = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:

    let
      # ---------------------------------------------------------
      # 🛠️ HELPER FUNCTION
      # ---------------------------------------------------------
      makeBravePwa = name: url: icon: startupClass: {
        name = "pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
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
          categories = [
            "Network"
            "WebBrowser"
          ];
          mimeType = [
            "x-scheme-handler/https"
            "x-scheme-handler/http"
          ];
        };
      };

      # Custom icons
      # Notion
      notionIconFile = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/e/e9/Notion-logo.svg";
        sha256 = "0q0i6cz44q0b54w0gm5lcndg8c7fi4bxavf1ylwr6v8nv22s2lhv";
      };

      # Apple music
      appleMusicIconFile = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/5/5f/Apple_Music_icon.svg";
        sha256 = "0lw10k2x25gnhjykllf0crkwff43a69i9pmsglmhnyhbsmx3qz71";
      };

      # YouTube
      youtubeIcon = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/f/fd/YouTube_full-color_icon_%282024%29.svg";
        sha256 = "8igmt9medFu9pU3EIcLC8IY3OyAMXn97QExNecPfaOI=";
      };

      # Youtube music
      youtubeMusicIcon = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/6/6a/Youtube_Music_icon.svg";
        sha256 = "02wdzksr3viwys3rzz9b10p2fl9vra2izxfnjswpc8b8nzwskyrb";
      };

      # Radio fm1-Switzerland
      radioFM1Icon = ../../src/svg-images/entertainment/radioFM1Icon.svg;
    in
    {
      home.packages = [ pkgs.brave ];

      xdg.desktopEntries = builtins.listToAttrs [
        # Manual Apps
        (makeBravePwa "YouTube" "https://www.youtube.com" "${
          youtubeIcon
        }" "brave-www.youtube.com__-Default")
        (makeBravePwa "YouTube Music" "https://music.youtube.com/" "${
          youtubeMusicIcon
        }" "brave-music.youtube.com__-Default")
        (makeBravePwa "Apple Music" "https://music.apple.com/ch/home?l=en" "${
          appleMusicIconFile
        }" "brave-music.apple.com__ch_home-Default")
        (makeBravePwa "Notion" "https://www.notion.so/" "${notionIconFile}" "brave-www.notion.so__-Default")
        (makeBravePwa "Radio fm1-Switzerland" "https://www.radiofm1.ch" "${
          radioFM1Icon
        }" "brave-www.radiofm1.ch__-Default")

        # Self-Hosted / Home Lab
        (makeBravePwa "Dashboard-Glance" "https://glance.nicolkrit.ch/" "utilities-system-monitor"
          "brave-glance.nicolkrit.ch__-Default"
        )
        (makeBravePwa "NAS" "https://nas.nicolkrit.ch" "network-server" "brave-nas.nicolkrit.ch__-Default")
        (makeBravePwa "Linkwarden" "https://linkwarden.nicolkrit.ch/dashboard" "emblem-favorite"
          "brave-linkwarden.nicolkrit.ch__dashboard-Default"
        )
        (makeBravePwa "OwnCloud" "https://owncloud.nicolkrit.ch/" "folder-cloud"
          "brave-owncloud.nicolkrit.ch__-Default"
        )

        # Cloud Services
        (makeBravePwa "Proton Mail" "https://mail.proton.me/u" "internet-mail"
          "brave-mail.proton.me__u-Default"
        )
        (makeBravePwa "Proton Drive" "https://drive.proton.me/u/0/" "folder-remote"
          "brave-drive.proton.me__u_0_-Default"
        )
        (makeBravePwa "Google Gemini" "https://gemini.google.com/app" "utilities-terminal"
          "brave-gemini.google.com__app-Default"
        )
        (makeBravePwa "Nix Search" "https://search.nixos.org/packages" "system-search"
          "brave-search.nixos.org__packages-Default"
        )
        (makeBravePwa "GitHub" "https://github.com/" "vcs-git" "brave-github.com__-Default")
        (makeBravePwa "Reddit" "https://www.reddit.com/" "internet-news-reader"
          "brave-www.reddit.com__-Default"
        )

        # Entertainments
      ];
    };
}
