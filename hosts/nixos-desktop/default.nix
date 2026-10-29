{ delib
, pkgs
, lib
, inputs
, ...
}:
let
  # 🌟 CORE APPS & THEME
  myBrowser = "zen-beta";
  myTerminal = "kitty";
  myShell = "fish";
  myEditor = "nvim";
  myFileManager = "yazi";
  myLocale = "en_US.UTF-8";

  mangoScratch = pkgs.writeShellApplication {
    name = "mango-scratch";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      mon=$(mmsg get all-monitors | jq -r '[.monitors[] | select(.active) | .name][0] // empty' || true)
      active=$(mmsg get all-clients | jq --arg m "$mon" '[.clients[] | select(.monitor == $m and .is_visible and (.is_global | not) and (.is_unglobal | not) and (.tags | index(0)))] | length' || echo 0)
      if (( ''${active:-0} == 0 )); then
        mmsg dispatch toggle_special_tag || true
      fi
      exec "$@"
    '';
  };

  mangoPlace = pkgs.writeShellApplication {
    name = "mango-place";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      out=$1
      pat=$2
      shift 3
      before=$(mmsg get all-clients | jq -c '[.clients[].id]' || echo '[]')
      mmsg dispatch "focusmon,$out" || true
      "$@" &
      for _ in $(seq 60); do
        sleep 0.5
        found=$(mmsg get all-clients | jq -r --argjson b "$before" --arg p "$pat" '[.clients[] | select((.appid | test($p)) and ((.id as $i | $b | index($i)) == null))][0] | if . then "\(.id) \(.monitor)" else empty end' || true)
        if [[ -n $found ]]; then
          read -r id mon <<< "$found"
          if [[ $mon != "$out" ]]; then
            mmsg dispatch "tagmon,$out,1 client,$id"
          fi
          break
        fi
      done
    '';
  };
  myGitUserName = "Krit Pio Nicol";

  # Own profile dir: --name only takes effect on a separate (--no-remote) instance
  scratchBrowserCmd = "${myBrowser} --no-remote --profile $HOME/.local/share/scratch-browser --name scratch-browser";

  # 🌟 HYPRLAND APP WORKSPACES (Keep 1 and 6 free. Keyboard key 0 = 10)
  appWorkspaces = {
    chat = "9";
    editor = "2";
    entertainment = "7";
    fileManager = "3";
    other = "10";
    terminal = "8";
    vm = "4";
  };

  silent = workspace: "${workspace} silent";
  workspaceRules =
    workspace: classes:
    map
      (class: {
        match.class = class;
        inherit workspace;
      })
      classes;

  termApps = [
    "helix"
    "hx"
    "lf"
    "nano"
    "neovim"
    "nnn"
    "nvim"
    "ranger"
    "vim"
    "yazi"
  ];
  smartLaunch =
    app: if builtins.elem app termApps then "${myTerminal} --class ${app} -e ${app}" else app;

  # 🌟 DESKTOP MAP & RESOLVE FUNCTION
  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "brave" = "brave-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";

  langLayout = {
    "format-en" = "🇺🇸-EN";
    "format-it" = "🇮🇹-IT";
    "format-de" = "🇩🇪-DE";
    "format-fr" = "🇫🇷-FR";
  };

  pinnedApps = [
    (resolve myBrowser)
    (resolve myEditor)
    (resolve myFileManager)
    "github-desktop.desktop"
    "LocalSend.desktop"
    "proton-pass.desktop"
    "com.actualbudget.actual.desktop"
    "com.rtosta.zapzap.desktop"
  ];
in

delib.host {
  name = "nixos-desktop";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { myconfig, ... }:
    {
      constants = {
        hostname = "nixos-desktop";
        mainLocale = myLocale;

        homeStateVersion = "25.11";

        # No LUKS on this host, so there's no encryption boundary to protect either way.
        emergencyAccess = true;

        user = "krit";
        gitUserName = myGitUserName;
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        wallpapers = [
          {
            targetMonitor = "DP-1";

            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/fr0st-xyz/wallz/wallz-main/Nordic%20Blue/02.%20Nordic%20Blue.jpg";
            wallpaperSHA256 = "0w7699lvxsvflxzb0xzml3cph6fgnl8pn707822jrdsh8h8lnpxa";

            videoURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-videos-gifs/landscape/girl-desk-working.MP4";
            videoSHA256 = "0q6asqgcq0n5va8210v5jhqlqw7nzw1i5wdr8cn8bccj316fnfgy";
          }
          {
            targetMonitor = "DP-2";

            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/fr0st-xyz/wallz/wallz-main/Nordic%20Blue/03.%20Nordic%20Blue.jpg";
            wallpaperSHA256 = "1p55hqqmwrvr8xbsxk2z3brb5x3y7ywsckyvlcl431i7w37j15c3";

            videoURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-videos-gifs/portrait/purple-car.mp4";
            videoSHA256 = "0g1gxwhwbg7brglwxg069ivacs33p7hmy4mn7gkz9zh4xlwrmag4";
          }
          {
            targetMonitor = "*";

            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/fr0st-xyz/wallz/wallz-main/Nordic%20Blue/01.%20Nordic%20Blue.jpg";
            wallpaperSHA256 = "0q4simvbyvjwrzh1nv0skxygz5rdr2gfrbhmbiixj3q04k8dqfxh";
          }
        ];

        theme = {
          base16Theme = "catppuccin-mocha";
          catppuccin = true;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "sapphire";
        };

        keyboardLayout = "us,it,de,fr";
        keyboardVariant = "alt-intl,,,";

        weather = "Lugano";

        timeZone = "Europe/Zurich";

        terminal.name = myTerminal;
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      attic = {
        enable = true;
        push = true;
        serverUrl = "http://${myconfig.krit.services.nas.host}:8081";
        cacheName = "krit-nix";
        publicKey = "krit-nix:whY2oqegMU3c1dowH39O7Z7I3aAfwMpB/WZNy0/wykk=";
        authTokenPath = "/run/secrets/attic-push-token";
      };

      bluetooth = {
        enable = true;
        autoEnableOnBoot = false;
      };

      cachix = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/cachix-push-token";
      };

      home-packages.enable = true;
      mime = {
        enable = true;
        videoPlayer = "vlc"; # mp4 mkv webm avi mov
        audioPlayer = "vlc"; # mp3 flac ogg wav m4a
        docEditor = "ai.storyteller.wordcraft"; # docx doc odt rtf
        sheetEditor = "ai.storyteller.gridcraft"; # xlsx xls ods csv
        slideEditor = "ai.storyteller.deckcraft"; # pptx ppt odp
        extraAppPackages = [ ]; # package names for role overrides, e.g. docEditor = "org.kde.kate.desktop" + [ "kate" ]
      };

      nh = {
        enable = true;
        gcd = "30d";
        gcn = "3";
      };
      nix-sweeps.enable = false;
      qt.enable = true;

      stylix = {
        enable = true;
        targets = { };
      };

      zram = {
        enable = true;
        zramPercent = 25;
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs = {
        atuin.enable = true;
        bat.enable = true;
        cava.enable = true;
        # mcpSecrets / mcpEnv default in users/krit/common/programs/claude-code/claude-code-personal.nix
        claude-code.enable = true;
        claude-desktop.enable = true;
        codex.enable = false;
        comma.enable = true;
        concord.enable = true;
        direnv.enable = true;
        doom.enable = false;
        eza.enable = true;
        fastfetch.enable = true;
        fzf = {
          enable = true;
          nix-search-tv.enable = false;
        };

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        google-antigravity.enable = false;
        headroom.enable = false;
        agent-reach = {
          enable = true;
          browserChannels = true;
        };
        herdr.enable = true;
        kitty.fontSize = 12;
        lazygit.enable = true;
        nix-alien.enable = true;
        nix-ld.enable = true;
        nltchNur = {
          enable = false;
          packages = [ ];
        };

        npm = {
          enable = true;
          packages = [
            "@actual-app/cli" # Actual Budget CLI
            "yoinks" # Video downloader
          ];
          hostPackages = [ ];
        };
        openlogi.enable = true;
        prismlauncher.enable = true;
        shell-aliases.enable = true;
        sidra.enable = true;
        skwdWall.enable = false;
        spotifyAdblock.enable = true;
        starship.enable = true;
        statix.enable = true;
        swayosd.enable = true;
        television.enable = false;
        tgt.enable = false;

        thunderbird = {
          enable = false;
          sopsFile = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
          accounts = [
            {
              name = "gmail";
              addressLocalSecretName = "thunderbird_gmail_address_local";
              addressDomainSecretName = "thunderbird_gmail_address_domain";
              realName = myGitUserName;
              flavor = "gmail.com";
              primary = true;
              authentication = "login";
              passwordSecretName = "thunderbird_gmail_app_password";
            }
            {
              name = "outlook";
              addressLocalSecretName = "thunderbird_outlook_address_local";
              addressDomainSecretName = "thunderbird_outlook_address_domain";
              realName = myGitUserName;
              flavor = "outlook.office365.com";
            }
          ];
        };

        tmux.enable = true;

        vicinae = {
          enable = true;
          extraExtensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
            agenda
            agent-skills-sh
            aria2-manager
            # bluetooth  # excluded upstream (vicinaehq/extensions flake.nix): node-gyp build fails in nix sandbox (dbus-next -> usocket), see vicinaehq/extensions#314
            case-converter
            color-converter
            fuzzy-files
            github
            it-tools
            nerdfont-search
            niri
            number-converter
            player-pilot
            podman
            port-killer
            power-profile
            process-manager
            pulseaudio
            ssh
            supergenpass
            wifi-commander
            wikipedia
            zoxide-recent-directories
          ];
          extraRayCastExtensions = [
            {
              name = "downloads-manager";
              hash = "sha256-GNEWSFWOsS7Ks0nPgqZrFqIYwdw1CYgswIhgAumvTOc=";
            }
            {
              name = "gif-search";
              hash = "sha256-aWIYh6tQbdZxT04TRVEc/HmgJUXFl0eMFpIZpCaIQ4U=";
            }
            {
              name = "google-search";
              hash = "sha256-nGTMIrSEgZX+gPpNc0tLme0MprVzA3Ap4gvEnq3n6IU=";
            }
            {
              name = "google-translate";
              installName = "translate";
              hash = "sha256-VhJ9wRnToUPccVIQwp4nxQ2ExkgukZIqqET5tS4RpfI=";
            }
            {
              name = "lorem-ipsum";
              hash = "sha256-zMhwb4imj79XByXbbVHqhQxso9Jj87bBuJNbqwEjMxs=";
            }
            {
              name = "notion";
              hash = "sha256-4ot/xa7PcwXB0ImsSyXBo3SXwfJgBlA0OLEv9HMYiO0=";
            }
            {
              name = "remove-paywall";
              hash = "sha256-i0jPsCbkl9X/Ka2fRYFHxk3COPxP8V+2C3dTdg6118c=";
            }
            {
              name = "video-downloader";
              hash = "sha256-/Q9VW59t4xgQROuumw/6DWENAWqada+GHszvMyVrT0w=";
            }
            {
              name = "visual-studio-code-recent-projects";
              installName = "visual-studio-code";
              hash = "sha256-fhTmPfLoFpU2wuPHlL0WlLqtHBCLJ7/VMKjt3wLewQc=";
            }
          ];
          extraPackages = [
            pkgs.aria2 # Required by aria2-manager extension
            pkgs.pulseaudio # pactl, required by the pulseaudio extension
          ];
        };

        vikunja-desktop.enable = true;
        walker.enable = false;
        zathura.enable = true;
        zoxide.enable = true;

        # ---------------------------------------------------------------
        # 🐚 SHELLS
        # ---------------------------------------------------------------
        caelestia = {
          enable = false;
          enableOnHyprland = true;
        };

        noctalia = {
          enable = false;
          enableOnHyprland = false;
          enableOnNiri = true;
          enableOnMango = false;
        };

        # ---------------------------------------------------------------
        # 🪟 WINDOW MANAGERS
        # ---------------------------------------------------------------
        hyprland = {
          enable = true;
          terminalOpacity = 0.9;
          monitors = [
            {
              output = "DP-1";
              mode = "3840x2160@240";
              position = "1440x560";
              scale = 1.5;
              bitdepth = 10;
            }
            {
              output = "DP-2";
              mode = "3840x2160@144";
              position = "0x0";
              scale = 1.5;
              transform = 1;
              bitdepth = 10;
            }
            {
              output = "HDMI-A-1";
              mode = "1920x1080@60";
              position = "0x0";
              scale = 1;
              mirror = "DP-1";
            }
          ];
          execOnce = [
            myBrowser
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
            "uwsm app -- pwa-youtube.desktop"
            "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
          ];
          monitorWorkspaces = map
            (n: {
              workspace = toString n;
              monitor = if n <= 5 then "DP-1" else "DP-2";
            })
            (lib.range 1 10);

          windowRules =
            workspaceRules appWorkspaces.editor [ "^(${myEditor})$" ]
            ++ workspaceRules (silent appWorkspaces.editor) [
              "^(code)$"
              "^(nvim-editor)$"
              "^(org.kde.kate)$"
              "^(jetbrains-pycharm-ce)$"
              "^(jetbrains-Clion)$"
              "^(jetbrains-idea)$"
            ]
            ++ workspaceRules (silent appWorkspaces.fileManager) [
              "^(org.kde.dolphin)$"
              "^(thunar)$"
              "^(${myFileManager})$"
              "^(ranger)$"
              "^(org.gnome.Nautilus)$"
              "^(nemo)$"
            ]
            ++ workspaceRules (silent appWorkspaces.vm) [ "^(winboat)$" ]
            ++ workspaceRules (silent appWorkspaces.other) [ "^(Actual)$" ]
            ++ workspaceRules (silent appWorkspaces.entertainment) [
              "^(org.jellyfin.JellyfinDesktop)$"
              "^(de\\.haeckerfelix\\.Shortwave)$"
              "^(brave-browser)$"
              "^(brave-.*\\..*)$"
              "(?i)spotify"
              "^(sidra)$"
            ]
            ++ workspaceRules (silent appWorkspaces.terminal) [
              "^(${myTerminal})$"
              "^(alacritty)$"
              "^(foot)$"
              "^(xfce4-terminal)$"
              "^(com.system76.CosmicTerm)$"
              "^(org.kde.konsole)$"
              "^(gnome-terminal)$"
              "^(XTerm)$"
            ]
            ++ workspaceRules (silent appWorkspaces.chat) [
              "^(discord)$"
              "^(org.telegram.desktop)$"
              "^(whatsapp-electron)$"
              "^(com.rtosta.zapzap)$"
            ]
            ++ workspaceRules appWorkspaces.other [ "(?i).*zathura.*" ]
            ++ [
              {
                match.class = "^winboat-.*$";
                workspace = appWorkspaces.vm;
                suppress_event = "fullscreen maximize activate activatefocus";
                no_initial_focus = true;
                no_anim = true;
                rounding = 0;
                no_shadow = true;
                no_blur = true;
                opaque = true;
              }
            ];
        };

        mango = {
          enable = true;
          monitors = [
            "name:^DP-1$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
            "name:^DP-2$,width:3840,height:2160,refresh:144,x:0,y:0,scale:1.5,rr:1"
            "name:^HDMI-A-1$,width:1920,height:1080,refresh:60,x:4000,y:560,scale:1,disable:1"
          ];
          monitorLayouts = {
            "DP-1" = "center_tile";
            "DP-2" = "vertical_deck";
            "HDMI-A-1" = "scroller";
          };
          execOnce = [
            # DP-1
            "sh -c 'sleep 3 && ${myTerminal} --class mango-startup-fileManager -e ${myFileManager}'"
            "sh -c 'sleep 6 && ${myTerminal} --class mango-startup-editor -e ${myEditor}'"
            "sh -c 'sleep 9 && exec ${lib.getExe mangoPlace} DP-1 ^${myBrowser}$ -- ${myBrowser}'"

            # DP-2
            "sh -c 'sleep 12 && ${myTerminal} --class mango-startup-terminal'"
            "sh -c 'sleep 15 && ${lib.getExe' pkgs.gtk3 "gtk-launch"} pwa-youtube'"
            "sh -c 'sleep 18 && flatpak run com.rtosta.zapzap'"
          ];
          windowRules = [
            "monitor:^DP-1$,app_id:^mango-startup-fileManager$"
            "monitor:^DP-1$,app_id:^mango-startup-editor$"
            "monitor:^DP-2$,app_id:^brave-www\\.youtube\\.com__-Default$"
            "monitor:^DP-2$,app_id:^mango-startup-terminal$"
            "monitor:^DP-2$,app_id:^com\\.rtosta\\.zapzap$"
            "is_floating:1,width:0.8,height:0.8,tags:0,app_id:^scratch-term$"
            "is_floating:1,width:0.8,height:0.8,tags:0,app_id:^scratch-fs$"
            "is_floating:1,width:0.8,height:0.8,tags:0,app_id:^scratch-browser$"
          ];
          extraBinds = [
            "SUPER+SHIFT,Return,spawn,${lib.getExe mangoScratch} ${myTerminal} --class scratch-term"
            "SUPER+SHIFT,F,spawn,${lib.getExe mangoScratch} ${myTerminal} --class scratch-fs -e ${myFileManager}"
            "SUPER+SHIFT,B,spawn,sh -c 'exec ${lib.getExe mangoScratch} ${scratchBrowserCmd}'"
          ];
        };

        niri = {
          enable = true;
          outputs = {
            "DP-1" = {
              mode = {
                width = 3840;
                height = 2160;
                refresh = 240.0;
              };
              scale = 1.5;
              position = {
                x = 1440;
                y = 560;
              };
            };
            "DP-2" = {
              mode = {
                width = 3840;
                height = 2160;
                refresh = 144.0;
              };
              scale = 1.5;
              position = {
                x = 0;
                y = 0;
              };
              transform = {
                rotation = 90;
                flipped = false;
              };
            };
            # I-17: niri cannot mirror; HDMI-A-1 is the JetKVM (hyprland mirrors it, mango disables it), so disable it
            "HDMI-A-1" = {
              enable = false;
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'" # Sleep necessary to allow loading right polarity
            "sh -c 'sleep 30 && niri msg action focus-column-first'" # Refocus browser after all windows are up
          ];
        };

        # ---------------------------------------------------------------
        # 📊 WAYBARS
        # ---------------------------------------------------------------
        waybar-hyprland = {
          enable = true;
          waybarLayout = langLayout;
          keyboardName = "mode-designs-m256w-h";
          waybarWorkspaceIcons = {
            "1" = "";
            "2" = ":";
            "3" = ":";
            "4" = "";
            "5" = "";
            "6" = "";
            "7" = ":";
            "8" = ":";
            "9" = ":󰭹";
            "10" = ":";
            "magic" = ":";
          };
        };

        waybar-mango = {
          enable = true;
          waybarLayout = langLayout;
        };

        waybar-niri = {
          enable = true;
          waybarLayout = langLayout;
        };

        # ---------------------------------------------------------------
        # 🖥️ DESKTOP ENVIRONMENTS
        # ---------------------------------------------------------------
        cosmic = {
          enable = true;
          monitors = [
            { output = "DP-1"; width = 3840; height = 2160; refresh = 240; scale = 1.5; x = 1440; y = 560; }
            { output = "DP-2"; width = 3840; height = 2160; refresh = 144; scale = 1.5; x = 0; y = 0; transform = 90; }
            { output = "HDMI-A-1"; enable = false; }
            { output = "*"; }
          ];
        };

        gnome = {
          enable = true;
          inherit pinnedApps;
          wmKeybindings = {
            switch-to-workspace-left = [
              "<Super>Page_Up"
              "<Super>KP_Prior"
              "<Super><Alt>Left"
              "<Control><Alt>Left"
            ];
            switch-to-workspace-right = [
              "<Super>Page_Down"
              "<Super>KP_Next"
              "<Super><Alt>Right"
              "<Control><Alt>Right"
            ];
            maximize = [
              "<Super>Up"
            ];
            minimize = [
              "<Super>h"
            ];
            toggle-maximized = [
              "<Super>m"
              "<Alt>F10"
            ];
          };
        };

        kde = {
          enable = true;
          inherit pinnedApps;
        };
      };

      # ---------------------------------------------------------------
      # ⚙️ SERVICES
      # ---------------------------------------------------------------
      services = {
        audio.enable = true;
        autotrash.enable = true;
        external = {
          dotfiles.enable = true;
          dotfiles-private.enable = true;
        };
        impermanence.enable = true;
        localsend.enable = true;
        rcloneMount.enable = true;
        resolved.enable = true;
        swaync.enable = true;
        tailscale.enable = true;

        locale = {
          enable = true;
          address = "it_CH.UTF-8";
          identification = "it_CH.UTF-8";
          measurement = "it_CH.UTF-8";
          monetary = "it_CH.UTF-8";
          name = "it_CH.UTF-8";
          numeric = "it_CH.UTF-8";
          paper = "it_CH.UTF-8";
          telephone = "it_CH.UTF-8";
          # 12h AM/PM, day-month-year, English names, Sunday week start; bare name on purpose (see the option docs)
          time = "en_IN";
        };

        hyprlock = {
          use24HourClock = false; # 12h lock clock
          avatarSize = 220;
          clockFontSize = 138;
          dateFontSize = 39;
          inputWidth = 460;
          inputHeight = 92;
        };

        hypridle = {
          enable = true;
          dimTimeout = 900;
          lockTimeout = 1800;
          screenOffTimeout = 3600;
        };

        sddm-astronaut = {
          enable = true;
          embeddedTheme = "hyprland_kath";
          use24HourClock = false; # 12h greeter clock
        };
        sddm-pixie = {
          enable = false;
          use24HourClock = false;
          background = "koi-fish.png";
          avatar = "face-512.jpg";
        };

        snapshots = {
          enable = true;
          retention = {
            hourly = "24";
            daily = "7";
            weekly = "4";
            monthly = "3";
            yearly = "2";
          };
        };
      };

      # ---------------------------------------------------------------
      # 🎭 SHARED SPECIALIZATIONS
      # ---------------------------------------------------------------
      specializations = {
        deep-focus.enable = true;
        guest.enable = true;
        safe-mode.enable = true;
        secure-travel.enable = true;
      };

      # ---------------------------------------------------------------
      # 👤 KRIT
      # ---------------------------------------------------------------
      krit = {
        commonSopsSecrets.enable = true;

        programs = {
          alacritty.enable = false;
          chromium.enable = false;
          claude-code-personal.enable = true;
          claude-code-wrappers.enable = true;
          direnv.enable = true;
          discord.enable = true;
          dolphin.enable = true;
          firefox.enable = false;
          helium.enable = false;
          kitty.enable = true;
          librewolf.enable = false;
          neovim.enable = true;
          proton-cli.enable = true;
          pwas.enable = true;
          ranger.enable = false;
          yazi.enable = true;
          zen-browser.enable = true;
        };

        services = {
          cloud = {
            googleDrive.enable = true;
            onedrivePersonal.enable = true;
            pcloud.enable = true;
            protonDrive.enable = true;
          };

          desktop = {
            flatpak.enable = true;
            local-packages.enable = true;
          };

          logitech.enable = false;

          nas = {
            desktop-borg-backup.enable = true;
            opencloud-mount.enable = true;
            smb.enable = true;
            sshfs.enable = true;
          };

          network-tools.enable = true;

          windows-mount = {
            enable = true;
            uuid = "7E70DDB470DD737F";
          };
        };

        # ---------------------------------------------------------------
        # 🎭 KRIT SPECIALIZATIONS
        # ---------------------------------------------------------------
        specializations = {
          entertainment.enable = true;
          school.enable = true;
        };

        # ---------------------------------------------------------------
        # 🔧 KRIT SYSTEM
        # ---------------------------------------------------------------
        system = {
          default-user.enable = true;
          git-ssh-signing.enable = true;
          ssh-config = {
            enable = true;
            gatewayAlias = true;
          };
          virtualisation.enable = true;
        };

        # ---------------------------------------------------------------
        # 🏠 KRIT HOME
        # ---------------------------------------------------------------
        home.base.enable = true;
      };
    };
}
