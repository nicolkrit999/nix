{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.programs.pwas";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    let
      makeChromePwa = name: url: icon: startupClass: {
        name = "pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
        value = {
          inherit name icon;
          genericName = "Web App";
          comment = "Launch ${name} as a PWA";

          exec = "${pkgs.google-chrome}/bin/google-chrome-stable --app=\"${url}\"";

          settings = {
            StartupWMClass = startupClass;
          };

          terminal = false;
          type = "Application";
          categories = [ "Network" ];
        };
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

      # Twitch
      twitchIcon = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/d/d3/Twitch_Glitch_Logo_Purple.svg";
        sha256 = "sha256-fRisDEuDaFX5E9UeiOl8s88uDeq+iyHvXHRKXb5A4Hg=";
      };
    in
    {
      home.packages = [ pkgs.google-chrome ];

      xdg.desktopEntries = builtins.listToAttrs [
        # Manual Apps
        (makeChromePwa "YouTube" "https://www.youtube.com" "${
          youtubeIcon
        }" "chrome-www.youtube.com__-Default")
        (makeChromePwa "YouTube Music" "https://music.youtube.com/" "${
          youtubeMusicIcon
        }" "chrome-music.youtube.com__-Default")
        (makeChromePwa "Twitch" "https://www.twitch.tv/" "${twitchIcon}" "chrome-www.twitch.tv__-Default")

        # Self-Hosted / Home Lab
        (makeChromePwa "Dashboard-Glance" "https://glance.nicolkrit.ch/" "utilities-system-monitor"
          "chrome-glance.nicolkrit.ch__-Default"
        )
        (makeChromePwa "NAS" "https://nicol-nas:9443/" "network-server" "chrome-nas.nicolkrit.ch__-Default")
        (makeChromePwa "Linkwarden" "https://linkwarden.nicolkrit.ch/dashboard" "emblem-favorite"
          "chrome-linkwarden.nicolkrit.ch__dashboard-Default"
        )

        # Cloud Services
        (makeChromePwa "Proton Mail" "https://mail.proton.me/u" "internet-mail"
          "chrome-mail.proton.me__u-Default"
        )
        (makeChromePwa "Proton Drive" "https://drive.proton.me/u/0/" "folder-remote"
          "chrome-drive.proton.me__u_0_-Default"
        )
      ];
    };
}
