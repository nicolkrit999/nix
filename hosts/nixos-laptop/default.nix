{ delib
, pkgs
, ...
}:
let
  # 🌟 CORE APPS & THEME
  myBrowser = "helium";
  myTerminal = "kitty";
  myShell = "fish";
  myEditor = "nvim";
  myFileManager = "yazi";
  myUserName = "krit";
  myLocale = "en_US.UTF-8";
  isCatppuccin = false;

  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    terminal = "4";
    chat = "5";
    browser-Entertainment = "6";
    vm = "7";
    other = "10";
  };

  # Add more if needed
  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];
  smartLaunch =
    app: if builtins.elem app termApps then "${myTerminal} --class ${app} -e ${app}" else app;

  # 🌟 DESKTOP MAP & RESOLVE FUNCTION
  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "chromium" = "chromium-browser.desktop";
    "brave" = "brave-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "Nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";
in

delib.host {
  name = "nixos-laptop";
  type = "laptop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-laptop";
        mainLocale = myLocale;

        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "krit";
        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = {
          name = myTerminal;
          cursorStyle = "block";
          cursorBlink = true;
          cursorBeamWidth = 3.0;
          animation = true;
        };
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        wallpapers = [
          /*
          {
            targetMonitor = "eDP-1";
            wallpaperURL = "https://github.com/nicolkrit999/wallpapers-repo/blob/main/wallpapers/Pictures/wallpapers/various/various-websites/wallpaperflare/wallpaperflare_nasa.jpg";
            wallpaperSHA256 = "1r8wdcgk5hg0rc1cs2g6dkvv5r9pshl1lsvw80nzqnk1iqc202gn";
          }
          */

          {
            targetMonitor = "*";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/AngelJumbo/gruvbox-wallpapers/gruvbox-wallpapers-main/wallpapers/anime/tanjiro-kamado-gruv.jpg";
            wallpaperSHA256 = "13lcg8wl8wlavqvh8mmm0xfjh6ysdwhn9w6rr2f32sfv8g5l7s33";
          }
        ];

        # ---------------------------------------------------------------
        # 🎨 THEMING
        # ---------------------------------------------------------------
        theme = {
          polarity = "dark";
          base16Theme = "gruvbox-material-dark-hard";
          catppuccin = false;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "teal";
        };

        # ---------------------------------------------------------------
        # 🪟 HYPRLAND CONSTANTS
        # ---------------------------------------------------------------
        hyprland = {
          rounding = 10;
          gap = 5; # Updated: 5px inner gap (2:1 ratio with outer gap via hyprland-main derivation)
          borderSize = 2; # 2px border: visible but not distracting
          terminalOpacity = 0.9;
        };

        # ---------------------------------------------------------------
        # 🌀 NIRI CONSTANTS
        # ---------------------------------------------------------------
        niri = {
          gap = 8; # 8px single gap — one grid unit, coherent with Hyprland values
          rounding = 10; # Matches hyprland.rounding for visual coherence
        };

        screenshots = "$HOME/Pictures/Screenshots";
        keyboardLayout = "us";
        keyboardVariant = "intl";

        weather = "Lugano";
        useFahrenheit = false;
        nixImpure = false;


        timeZone = "Europe/Zurich";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth.enable = true;

      cachix = {
        enable = true;
        push = false;
      };

      guest.enable = true;
      home-packages.enable = true;
      mime.enable = true;

      nh = {
        enable = true;
        gcd = "30d";
        gcn = "10";
      };
      qt.enable = true;

      zram = {
        enable = true;
        zramPercent = 25;
      };

      stylix = {
        enable = true;
        targets = {
          yazi.enable = false;
          cava.enable = true;
          kitty.enable = !isCatppuccin;
          alacritty.enable = !isCatppuccin;
          zathura.enable = !isCatppuccin;
          firefox.profileNames = [ myUserName ];
          librewolf.profileNames = [
            "default"
            "privacy"
          ];
        };
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs = {
        bat.enable = true;
        cava.enable = false;
        eza.enable = true;
        fzf.enable = true;
        fzf.nix-search-tv.enable = true;
        nix-ld.enable = false;
        nix-alien.enable = false;
        comma.enable = true;
        statix.enable = false;
        lazygit.enable = true;
        shell-aliases.enable = true;
        starship.enable = true;
        tmux.enable = true;
        walker.enable = true;
        television.enable = true;
        zoxide.enable = true;

        claude-code = {
          enable = true;
          mcpSecrets = [
            { sopsSecret = "openrouter_api_claude_code"; envVar = "OPENROUTER_API_KEY"; }
            { sopsSecret = "claude_mcp_actual_password"; envVar = "ACTUAL_PASSWORD"; }
            { sopsSecret = "claude_mcp_actual_sync_id"; envVar = "ACTUAL_SYNC_ID"; }
            { sopsSecret = "claude_mcp_actual_encryption_password"; envVar = "ACTUAL_BUDGET_ENCRYPTION_PASSWORD"; }
            { sopsSecret = "claude_mcp_context7_api_key"; envVar = "CONTEXT7_API_KEY"; }
            { sopsSecret = "claude_mcp_openai_api_key"; envVar = "OPENAI_API_KEY"; }
            { sopsSecret = "claude_mcp_milvus_token"; envVar = "MILVUS_TOKEN"; }
            { sopsSecret = "claude_mcp_github_token"; envVar = "GITHUB_TOKEN"; }
            { sopsSecret = "claude_mcp_portainer_token"; envVar = "PORTAINER_TOKEN"; }
          ];
          mcpEnv = {
            ACTUAL_SERVER_URL = "https://budget.nicolkrit.ch";
          };
        };

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        waybar-hyprland = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
          };

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

        waybar-niri = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
          };
        };

        waybar-mango = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
          };
        };

        caelestia = {
          enable = false;
          enableOnHyprland = true;
        };

        noctalia = {
          enable = false;
          enableOnHyprland = false;
          enableOnNiri = true;
        };

        mango = {
          enable = true;
          # Only the internal panel is declared here. Any externally connected
          # monitor (DP/HDMI/whatever) falls through to wlroots defaults:
          # preferred mode, scale 1.0, placed to the right of existing outputs.
          # Monitor-specific setups (home dock, etc.) live in specializations.
          monitors = [
            "name:^eDP-1$,width:3200,height:2000,refresh:120,x:0,y:0,scale:1.6"
          ];
          # Hotplugged monitors with no entry here get `defaultLayout` via the
          # fallback branch in mango-binds.nix (tagRules).
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
            "SUPER,Y,spawn,chromium-browser"

            "NONE,XF86Tools,viewtoleft_have_client,0"
            "NONE,XF86Launch5,viewtoright_have_client,0"
            "NONE,XF86Launch6,togglemaximizescreen,"
            "NONE,XF86Launch7,killclient,"
          ];
        };

        hyprland = {
          enable = true;
          monitors = [
            "eDP-1,3200x2000@120,0x0,1.6"
            ",preferred,auto,1"
          ];
          execOnce = [
            "hyprctl dispatch workspace 1"
            "[workspace 1 silent] ${myBrowser}"
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
            "sh -c 'sleep 5 && protonvpn-app --start-minimized'"
            "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
          ];

          monitorWorkspaces = [
            "1, monitor:eDP-1"
            "2, monitor:eDP-1"
            "3, monitor:eDP-1"
            "4, monitor:eDP-1"
            "5, monitor:eDP-1"
          ];

          windowRules = [
            # 1. Smart Launcher Rules
            "workspace ${appWorkspaces.editor}, class:^(${myEditor})$"
            "workspace ${appWorkspaces.fileManager}, class:^(${myFileManager})$"
            "workspace ${appWorkspaces.terminal}, class:^(${myTerminal})$"
            "workspace ${appWorkspaces.editor} silent, class:^(code)$"
            "workspace ${appWorkspaces.editor} silent, class:^(nvim-editor)$"
            "workspace ${appWorkspaces.editor} silent, class:^(org.kde.kate)$"
            "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-pycharm-ce)$"
            "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-Clion)$"
            "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-idea-ce)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(org.kde.dolphin)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(thunar)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(yazi)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(ranger)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(org.gnome.Nautilus)$"
            "workspace ${appWorkspaces.fileManager} silent, class:^(nemo)$"
            "workspace ${appWorkspaces.vm} silent, class:^(winboat)$"
            "workspace ${appWorkspaces.other} silent, class:^(Actual)$"
            "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(org.jellyfin.JellyfinDesktop)$"
            "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(chromium-browser)$"
            "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-browser)$"
            "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-.*\..*)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(kitty)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(alacritty)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(foot)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(xfce4-terminal)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(com.system76.CosmicTerm)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(org.kde.konsole)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(gnome-terminal)$"
            "workspace ${appWorkspaces.terminal} silent, class:^(XTerm)$"
            "workspace ${appWorkspaces.chat} silent, class:^(vesktop)$"
            "workspace ${appWorkspaces.chat} silent, class:^(org.telegram.desktop)$"
            "workspace ${appWorkspaces.chat} silent, class:^(whatsapp-electron)$"
            "workspace ${appWorkspaces.chat} silent, class:^(com.rtosta.zapzap)$"
            # Scratchpad rules
            "float, class:^(scratch-term)$"
            "center, class:^(scratch-term)$"
            "size 80% 80%, class:^(scratch-term)$"
            "workspace special:magic, class:^(scratch-term)$"
            "float, class:^(scratch-fs)$"
            "center, class:^(scratch-fs)$"
            "size 80% 80%, class:^(scratch-fs)$"
            "workspace special:magic, class:^(scratch-fs)$"
            "float, class:^(scratch-browser)$"
            "center, class:^(scratch-browser)$"
            "size 80% 80%, class:^(scratch-browser)$"
            "workspace special:magic, class:^(scratch-browser)$"
            # Winboat rules
            "workspace ${appWorkspaces.vm}, class:^winboat-.*$"
            "suppressevent fullscreen maximize activate activatefocus, class:^winboat-.*$"
            "noinitialfocus, class:^winboat-.*$"
            "noanim, class:^winboat-.*$"
            "norounding, class:^winboat-.*$"
            "noshadow, class:^winboat-.*$"
            "noblur, class:^winboat-.*$"
            "opaque, class:^winboat-.*$"
          ];

          extraBinds = [
            "$Mod SHIFT, return, exec, [workspace special:magic] ${myTerminal} --class scratch-term"
            "$Mod SHIFT, F, exec, [workspace special:magic] ${myTerminal} --class scratch-fs -e yazi"
            "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
            "$Mod,       Y, exec, chromium-browser"

            # 🖱️ LOGITECH MX MASTER Thumb button gesstures
            ", XF86Tools, workspace, m-1" # Swipe Left: Previous workspace on CURRENT monitor
            ", XF86Launch5, workspace, m+1" # Swipe Right: Next workspace on CURRENT monitor
            ", XF86Launch6, fullscreen" # Swipe Up: Maximize window (keeps gaps/bar)
            ", XF86Launch7, killactive" # Swipe Down: Close window
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
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'" # Sleep necessary to allow loading right polarity
            "sh -c 'sleep 17 && protonvpn-app --start-minimized'"
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

        gnome = {
          enable = false; # Gnome pulls lot of elements. Since i almost never use it keep it disabled to save battery and resources
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
          extraBinds = [
            {
              name = "Launch Chromium";
              command = "chromium";
              binding = "<Super>y";
            }
            # 🖱️ LOGITECH MX MASTER Thumb button gesstures
            { name = "Gesture Left (Prev Workspace)"; command = "${pkgs.wtype}/bin/wtype -M super -k Page_Up -m super"; binding = "XF86Tools"; }
            { name = "Gesture Right (Next Workspace)"; command = "${pkgs.wtype}/bin/wtype -M super -k Page_Down -m super"; binding = "XF86Launch5"; }
            { name = "Gesture Up (Maximize)"; command = "${pkgs.wtype}/bin/wtype -M super -k Up -m super"; binding = "XF86Launch6"; }
            { name = "Gesture Down (Close)"; command = "${pkgs.wtype}/bin/wtype -M super -M shift -k c -m shift -m super"; binding = "XF86Launch7"; }
          ];
        };

        cosmic = {
          enable = false;
        };

        kde = {
          enable = true;
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
          extraBinds = {
            "launch-chromium" = {
              key = "Meta+Y";
              command = "chromium";
            };
            # 🖱️ LOGITECH MX MASTER Thumb button gesstures
            "gesture-left" = { key = "XF86Tools"; command = "qdbus org.kde.KWin /KWin org.kde.KWin.previousDesktop"; };
            "gesture-right" = { key = "XF86Launch5"; command = "qdbus org.kde.KWin /KWin org.kde.KWin.nextDesktop"; };
            "gesture-up" = { key = "XF86Launch6"; command = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut \"Window Maximize\""; };
            "gesture-down" = { key = "XF86Launch7"; command = "qdbus org.kde.kglobalaccel /component/kwin invokeShortcut \"Window Close\""; };
          };
        };
      };

      # ---------------------------------------------------------------
      # ⚙️ SERVICES
      # ---------------------------------------------------------------
      services = {
        # Power management (mutually exclusive - only enable ONE)
        auto-cpufreq.enable = true; # Recommended: dynamic CPU scaling (uses official flake)
        tlp.enable = false; # Alternative: static power policies (uses NixOS native)

        audio.enable = true;
        hyprlock.enable = true;
        sddm-astronaut = {
          enable = true;
          embeddedTheme = "japanese_aesthetic";
          # background = ../../users/krit/src/wallpapers/girl-outline.png;
        };
        sddm-pixie = {
          enable = false;
          avatar = ../../users/krit/src/profile-picture/face-512.jpg;
        };
        impermanence.enable = true;
        nix-topology.enable = false;
        tailscale.enable = true;

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

        hypridle = {
          enable = true;
          dimTimeout = 180;
          lockTimeout = 300;
          screenOffTimeout = 600;
        };

        swaync = {
          enable = true;
          customSettings = {
            "mute-protonvpn" = {
              state = "ignored";
              app-name = ".*Proton.*";
            };
          };
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------

      krit.programs = {
        alacritty.enable = false;
        kitty.enable = true;
        chromium.enable = false;
        helium.enable = true;
        claude-code-wrappers.enable = true;
        direnv.enable = true;
        dolphin.enable = true;
        firefox.enable = false;
        librewolf.enable = true;
        neovim.enable = true;
        npm.enable = true;
        pwas.enable = true;
        ranger.enable = false;
        yazi.enable = true;
        zathura.enable = true;
      };


      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.laptop = {
        flatpak.enable = true;
        local-packages.enable = true;
      };

      krit.services.logitech = {
        enable = true;
        mouses = {
          mx-master-3s.enable = true;
          mx-master-4.enable = true;
          superlight.enable = true;
        };
      };


      krit.services.nas = {
        laptop-borg-backup.enable = true;
        owncloud.enable = true;
        smb.enable = true;
        sshfs.enable = false;
      };

      # ---------------------------------------------------------------
      # 🎭 KRIT SPECIALIZATIONS
      # ---------------------------------------------------------------
      krit.specializations = {
        home.enable = true;
        school.enable = true;
        entertainment.enable = true;
        deep-focus.enable = true;
        safe-mode.enable = true;
        secure-travel.enable = true;
      };

      # ---------------------------------------------------------------
      # 🔧 KRIT SYSTEM
      # ---------------------------------------------------------------
      krit.system = {
        swiss-locale.enable = true;
        git-ssh-signing.enable = true;
        default-user.enable = true;
        virtualisation.enable = true;
        resolved.enable = true;
        autotrash.enable = true;
        ssh-config.enable = true;
      };

      # ---------------------------------------------------------------
      # 🏠 KRIT HOME
      # ---------------------------------------------------------------
      krit.home.base.enable = true;

    };
}

