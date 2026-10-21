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
  myGitUserName = "Krit Pio Nicol";

  # Own profile dir: --name only takes effect on a separate (--no-remote) instance
  scratchBrowserCmd = "${myBrowser} --no-remote --profile $HOME/.local/share/scratch-browser --name scratch-browser";

  # 🌟 HYPRLAND APP WORKSPACES
  appWorkspaces = {
    chat = "5";
    editor = "2";
    entertainment = "6";
    fileManager = "3";
    other = "10";
    terminal = "4";
    vm = "7";
  };

  silent = workspace: "${workspace} silent";
  workspaceRules = workspace: classes: map (class: { match.class = class; inherit workspace; }) classes;
  scratchRule = class: {
    match.class = "^(${class})$";
    float = true;
    center = true;
    size = "80% 80%";
    workspace = "special:magic";
  };

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
    "vesktop.desktop"
    "com.actualbudget.actual.desktop"
    "com.rtosta.zapzap.desktop"
  ];
in

delib.host {
  name = "nixos-laptop";
  type = "laptop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { myconfig, ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-laptop";
        mainLocale = myLocale;

        homeStateVersion = "25.11";
        emergencyAccess = true;

        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "krit";
        gitUserName = myGitUserName;
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal.name = myTerminal;
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        videoPlayer = "vlc"; # mp4 mkv webm avi mov
        audioPlayer = "vlc"; # mp3 flac ogg wav m4a
        docEditor = "ai.storyteller.wordcraft"; # docx doc odt rtf
        sheetEditor = "ai.storyteller.gridcraft"; # xlsx xls ods csv
        slideEditor = "ai.storyteller.deckcraft"; # pptx ppt odp
        extraAppPackages = [ ]; # package names for role overrides, e.g. docEditor = "org.kde.kate.desktop" + [ "kate" ]

        wallpapers = [

          {
            targetMonitor = "eDP-1";
            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/various-websites/imgur/imgur_japan_2.jpg";
            wallpaperSHA256 = "1pkk3glmqjl2h2cgrx9jcwp069xh73d14nxhs6sijqh73vhj7wrg";
          }
          {
            targetMonitor = "*";
            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
            wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
          }
        ];

        # ---------------------------------------------------------------
        # 🎨 THEMING
        # ---------------------------------------------------------------
        theme = {
          base16Theme = "rose-pine-moon";

          catppuccin = false;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "sapphire";
        };

        keyboardLayout = "us,it,de,fr";
        keyboardVariant = "intl";

        weather = "Lugano";

        timeZone = "Europe/Zurich";
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
        autoEnableOnBoot = true;
      };

      cachix = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/cachix-push-token";
      };

      home-packages.enable = true;
      mime.enable = true;

      nh = {
        enable = true;
        gcd = "15d";
        gcn = "5";
      };
      nix-sweeps.enable = true;
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
        cava.enable = false;
        # mcpSecrets / mcpEnv default in users/krit/common/programs/claude-code/claude-code-personal.nix
        claude-code.enable = true;
        claude-desktop.enable = true;
        codex.enable = false;
        comma.enable = true;
        concord.enable = true;
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
        lazygit.enable = true;
        nix-alien.enable = false;
        nix-ld.enable = false;
        nltchNur = {
          enable = false;
          packages = [ ];
        };

        npm = {
          enable = true;
          packages = [
            "@actual-app/cli" # Actual Budget CLI
            "claudefm" # terminal music player
            "claude-token-counter" # Token usage counter for claude code
            "yoinks" # Video downloader
          ];
          hostPackages = [
            pkgs.yt-dlp # claudefm: stream source
            pkgs.mpv # claudefm: playback
          ];
        };
        prismlauncher.enable = true;
        shell-aliases.enable = true;
        sidra.enable = true;
        skwdWall.enable = false;
        spotifyAdblock.enable = true;
        starship.enable = true;
        statix.enable = false;
        swayosd.enable = true;
        television.enable = true;
        tgt.enable = true;

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
            gnome-settings
            it-tools
            kde-system-settings
            nerdfont-search
            niri
            number-converter
            player-pilot
            podman
            port-killer
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
        zen.browser.enable = true;
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
          monitors = [
            {
              output = "eDP-1";
              mode = "3200x2000@120";
              position = "0x0";
              scale = 1.6;
            }
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];
          execOnce = [
            "hyprctl dispatch 'hl.dsp.focus({ workspace = \"1\" })'"
            "[workspace 1 silent] ${myBrowser}"
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
            "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
          ];

          monitorWorkspaces = map
            (n: {
              workspace = toString n;
              monitor = "eDP-1";
            })
            (lib.range 1 5);

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
              "^(vesktop)$"
              "^(org.telegram.desktop)$"
              "^(whatsapp-electron)$"
              "^(com.rtosta.zapzap)$"
            ]
            ++ map scratchRule [
              "scratch-term"
              "scratch-fs"
              "scratch-browser"
            ]
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

          extraBinds = [
            {
              _args = [
                "SUPER + SHIFT + return"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-term")'')
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + F"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-fs -e ${myFileManager}")'')
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + B"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${scratchBrowserCmd}")'')
              ];
            }

            {
              _args = [
                "XF86Tools"
                (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m-1" })'')
              ];
            }
            {
              _args = [
                "XF86Launch5"
                (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m+1" })'')
              ];
            }
            {
              _args = [
                "XF86Launch6"
                (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
              ];
            }
            {
              _args = [
                "XF86Launch7"
                (lib.generators.mkLuaInline "hl.dsp.window.close()")
              ];
            }
          ];
        };

        mango = {
          enable = false;
          monitors = [
            "name:^eDP-1$,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.6"
          ];
          monitorLayouts = {
            "eDP-1" = "scroller";
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'"
          ];
          extraBinds = [
            "NONE,XF86Tools,viewtoleft_have_client,0"
            "NONE,XF86Launch5,viewtoright_have_client,0"
            "NONE,XF86Launch6,togglefullscreen,"
            "NONE,XF86Launch7,killclient,"
          ];
        };

        niri = {
          enable = true;
          outputs = {
            "eDP-1" = {
              mode = {
                width = 3200;
                height = 2000;
                refresh = 120.0;
              };
              scale = 1.6; # same scale as hyprland/mango
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'"
            "sh -c 'sleep 27 && niri msg action focus-column-first'" # Refocus browser after all windows are up
          ];
          extraBinds = {
            # 🖱️ LOGITECH MX MASTER Thumb button gestures
            "XF86Tools".action.focus-workspace-up = [ ]; # Swipe Left: Previous workspace
            "XF86Launch5".action.focus-workspace-down = [ ]; # Swipe Right: Next workspace
            "XF86Launch6".action.maximize-column = [ ]; # Swipe Up: Maximize column
            "XF86Launch7".action.close-window = [ ]; # Swipe Down: Close window
          };
        };

        # ---------------------------------------------------------------
        # 📊 WAYBARS
        # ---------------------------------------------------------------
        waybar-hyprland = {
          enable = true;
          waybarLayout = langLayout;
          waybarWorkspaceIcons = {
            "1" = "";
            "2" = ":";
            "3" = ":";
            "4" = ":";
            "5" = ":󰭹";
            "6" = ":";
            "7" = "";
            "8" = "";
            "9" = "";
            "10" = ":";
            "magic" = ":";
          };
        };

        waybar-mango = {
          enable = false;
          waybarLayout = langLayout;
        };

        waybar-niri = {
          enable = true;
          waybarLayout = langLayout;
        };

        # ---------------------------------------------------------------
        # 🖥️ DESKTOP ENVIRONMENTS
        # ---------------------------------------------------------------
        cosmic.enable = false;

        gnome = {
          enable = false;
          inherit pinnedApps;
          # 🖱️ LOGITECH MX MASTER Thumb gestures: left/right = workspace, up = maximize, down = minimize; <Super>m toggles maximize
          wmKeybindings = {
            switch-to-workspace-left = [ "<Super>Page_Up" "<Super>KP_Prior" "<Super><Alt>Left" "<Control><Alt>Left" "XF86Tools" ];
            switch-to-workspace-right = [ "<Super>Page_Down" "<Super>KP_Next" "<Super><Alt>Right" "<Control><Alt>Right" "XF86Launch5" ];
            maximize = [ "<Super>Up" "XF86Launch6" ];
            minimize = [ "<Super>h" "XF86Launch7" ];
            toggle-maximized = [ "<Super>m" "<Alt>F10" ];
          };
        };

        kde = {
          enable = true;
          inherit pinnedApps;
          extraBinds = {
            # 🖱️ LOGITECH MX MASTER Thumb button gestures
            "gesture-left" = {
              key = "XF86Tools";
              command = "qdbus org.kde.KWin /KWin org.kde.KWin.previousDesktop";
            };
            "gesture-right" = {
              key = "XF86Launch5";
              command = "qdbus org.kde.KWin /KWin org.kde.KWin.nextDesktop";
            };
            "gesture-up" = {
              key = "XF86Launch6";
              command = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut \"Window Maximize\"";
            };
            "gesture-down" = {
              key = "XF86Launch7";
              command = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut \"Window Close\"";
            };
          };
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

        # Power management: auto-cpufreq and tlp are mutually exclusive (asserted); thermald is independent
        auto-cpufreq.enable = true;
        tlp.enable = false;
        thermald.enable = false;

        hypridle = {
          enable = true;
          dimTimeout = 180;
          lockTimeout = 300;
          screenOffTimeout = 600;
        };

        sddm-astronaut = {
          enable = false;
          embeddedTheme = "pixel_sakura";
          background = "imgur_japan_33.jpg";
        };
        sddm-pixie = {
          enable = true;
          background = "imgur_japan_33.jpg";
          avatar = "face-512.jpg";
        };

        snapshots = {
          enable = true;
          retention = {
            hourly = "5";
            daily = "3";
            weekly = "2";
            monthly = "1";
            yearly = "0";
          };
        };
      };

      # ---------------------------------------------------------------
      # 🎭 SHARED SPECIALIZATIONS
      # ---------------------------------------------------------------
      specializations = {
        deep-focus.enable = false;
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
          dolphin.enable = true;
          firefox.enable = false;
          helium.enable = false;
          kitty.enable = true;
          librewolf.enable = true;
          neovim.enable = true;
          proton-cli.enable = false;
          pwas.enable = true;
          ranger.enable = false;
          yazi.enable = true;
          zathura.enable = true;
        };

        services = {
          cloud = {
            googleDrive.enable = true;
            onedrivePersonal.enable = false;
            pcloud.enable = true;
            protonDrive.enable = true;
          };

          laptop = {
            camera.enable = false; # 2026-10-21: disabled, ipu7 psys module caused a boot kernel panic
            flatpak.enable = true;
            local-packages.enable = true;
          };

          logitech = {
            enable = true;
            mouses = {
              mx-master-3s.enable = true;
              mx-master-4.enable = true;
              superlight.enable = false;
            };
          };

          nas = {
            laptop-borg-backup.enable = true;
            opencloud-mount.enable = true;
            smb.enable = true;
            sshfs.enable = false;
          };

          network-tools.enable = true;

          windows-mount = {
            enable = true;
            uuid = "26C47F73C47F43D9"; # 2T NTFS = Windows C:, not the 845M recovery partition
          };
        };

        # ---------------------------------------------------------------
        # 🎭 KRIT SPECIALIZATIONS
        # ---------------------------------------------------------------
        specializations = {
          entertainment.enable = false;
          home.enable = true;
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
          swiss-locale.enable = true;
          virtualisation.enable = true;
        };

        # ---------------------------------------------------------------
        # 🏠 KRIT HOME
        # ---------------------------------------------------------------
        home.base.enable = true;
      };
    };
}
