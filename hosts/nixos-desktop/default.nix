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
  myLocale = "en_US.UTF-8";

  # 🌟 HYPRLAND APP WORKSPACES (Keep 1 and 6 free. Keyboard key 0 = 10)
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
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
  name = "nixos-desktop";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      constants = {
        hostname = "nixos-desktop";
        mainLocale = myLocale;

        user = "krit";
        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        wallpapers = [
          {
            targetMonitor = "DP-1";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/ChrisTitusTech/ChrisTitusTech/nord-background/at_the_coffeshop.png";
            wallpaperSHA256 = "14jnknqia3p2szg9qzyi3h2kb0pz0wj7ypvzx0fi449pq54vr931";
          }
          {
            targetMonitor = "*";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/linuxdotexe/nordic-wallpapers/ign_Carvan-2.png";
            wallpaperSHA256 = "03n3kh7mz26cnyah1pnnrs2msxmdd6s9qwcnj9pxzif1q2xpdv4r";
          }
        ];

        theme = {
          polarity = "dark";
          base16Theme = "nord";
          catppuccin = false;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "teal";
        };

        screenshots = "$HOME/Pictures/Screenshots";
        keyboardLayout = "us,it,de,fr";
        keyboardVariant = "intl,,,";

        weather = "Lugano";
        useFahrenheit = false;
        nixImpure = false;


        timeZone = "Europe/Zurich";

        hyprland = {
          rounding = 10;
          gap = 5;
          borderSize = 2;
          terminalOpacity = 0.9;
        };

        niri = {
          gap = 8;
          rounding = 10;
        };

        terminal = {
          name = myTerminal;
          cursorStyle = "block";
          cursorBlink = true;
          cursorBeamWidth = 3.0;
          animation = true;
        };
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth.enable = true;

      cachix = {
        enable = true;
        push = true; # Only the builder must have this true (for now "nixos-desktop")
      };

      home-packages.enable = true;
      mime.enable = true;

      nh = {
        enable = true;
        gcd = "30d";
        gcn = "3";
      };
      qt.enable = true;

      zram = {
        enable = true;
        zramPercent = 25;
      };

      stylix = {
        enable = true;
        targets = { };
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs = {
        bat.enable = true;
        cava.enable = true;
        eza.enable = true;
        fzf.enable = true;
        fzf.nix-search-tv.enable = true;
        nix-ld.enable = true;
        nix-alien.enable = true;
        comma.enable = true;
        npm.enable = true;
        statix.enable = true;
        lazygit.enable = true;
        shell-aliases.enable = true;
        starship.enable = true;
        tmux.enable = true;
        walker.enable = true;
        television.enable = true;
        zoxide.enable = true;
        zen.browser.enable = true;

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

        claude-desktop.enable = true;

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        waybar-hyprland = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
            "format-it" = "🇮🇹-IT";
            "format-de" = "🇩🇪-DE";
            "format-fr" = "🇫🇷-FR";
          };

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

        waybar-niri = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
            "format-it" = "🇮🇹-IT";
            "format-de" = "🇩🇪-DE";
            "format-fr" = "🇫🇷-FR";
          };
        };

        waybar-mango = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
            "format-it" = "🇮🇹-IT";
            "format-de" = "🇩🇪-DE";
            "format-fr" = "🇫🇷-FR";
          };
        };

        caelestia = {
          enable = false;
          enableOnHyprland = false;
        };

        noctalia = {
          enable = false;
          enableOnHyprland = false;
          enableOnNiri = false;
        };

        mango = {
          enable = true;
          monitors = [
            "name:^DP-1$,width:3840,height:2160,refresh:240,x:1440,y:560,scale:1.5"
            "name:^DP-2$,width:3840,height:2160,refresh:144,x:0,y:0,scale:1.5,rr:1"
            "name:^HDMI-A-1$,width:1920,height:1080,refresh:60,x:4000,y:560,scale:1"
          ];
          monitorLayouts = {
            "DP-1" = "center_tile";
            "DP-2" = "vertical_scroller";
            "HDMI-A-1" = "scroller";
          };
          # Each startup app spawned with a unique --class so windowRules below
          # pin it to a specific monitor at startup only. Manual launches use
          # the default class and remain free to land on any monitor/tag.
          # Spawn order matters: with center_tile/vertical_scroller the first
          # spawn becomes master/leftmost, so the order below dictates layout.
          execOnce = [
            # DP-1
            "sh -c 'sleep 3 && ${myTerminal} --class mango-startup-fileManager -e ${myFileManager}'"
            "sh -c 'sleep 6 && ${myTerminal} --class mango-startup-editor -e ${myEditor}'"
            "sh -c 'sleep 9 && ${myBrowser} --class=mango-startup-browser'"

            # DP-2
            "sh -c 'sleep 12 && brave --app=https://www.youtube.com --password-store=gnome --class=mango-startup-youtube'"
            "sh -c 'sleep 15 && ${myTerminal} --class mango-startup-terminal'"
            "sh -c 'sleep 18 && flatpak run com.rtosta.zapzap'"
          ];
          windowRules = [
            "monitor:DP-1,appid:^mango-startup-fileManager$"
            "monitor:DP-1,appid:^mango-startup-editor$"
            "monitor:DP-1,appid:^mango-startup-browser$"
            "monitor:DP-2,appid:^brave-.*\\..*$"
            "monitor:DP-2,appid:^mango-startup-terminal$"
            "monitor:DP-2,appid:^com.rtosta.zapzap$"
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
            "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
            "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"
            "HDMI-A-1,1920x1080@60, 0x0, 1, mirror, DP-1"
          ];
          execOnce = [
            "${myBrowser}"
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
            "sh -c 'sleep 5 && protonvpn-app --start-minimized'"
            "uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
            "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
          ];
          monitorWorkspaces = [
            "1, monitor:DP-1"
            "2, monitor:DP-1"
            "3, monitor:DP-1"
            "4, monitor:DP-1"
            "5, monitor:DP-1"
            "6, monitor:DP-2"
            "7, monitor:DP-2"
            "8, monitor:DP-2"
            "9, monitor:DP-2"
            "10, monitor:DP-2"
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

            # 2. Scratchpad rules
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

            # 3. Winboat rules
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
            "HDMI-A-1" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 60.0;
              };
              scale = 1.0;
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'" # Sleep necessary to allow loading right polarity
            "sh -c 'sleep 17 && chromium-browser'"
            "sh -c 'sleep 19 && protonvpn-app --start-minimized'"
            "sh -c 'sleep 30 && niri msg action focus-column-first'" # Refocus browser after all windows are up
          ];
          extraBinds = {
            # 🖱️ LOGITECH MX MASTER Thumb button gestures
            "XF86Tools".action.focus-column-left = [ ]; # Swipe Left: Focus previous column
            "XF86Launch5".action.focus-column-right = [ ]; # Swipe Right: Focus next column
            "XF86Launch6".action.maximize-column = [ ]; # Swipe Up: Maximize column
            "XF86Launch7".action.close-window = [ ]; # Swipe Down: Close window
          };
        };

        gnome = {
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
          enable = true;
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
        external.dotfiles.enable = true; # Symlinks ~/dotfiles/* into $HOME (out-of-store)

        audio.enable = true;
        hyprlock.enable = true;
        sddm-astronaut = {
          enable = true;
          # embeddedTheme = "japanese_aesthetic";
          background = ../../users/krit/src/wallpapers/ign_unicorn.png;
        };
        sddm-pixie = {
          enable = false;
          background = ../../users/krit/src/wallpapers/Cat_at_Play.png;
          avatar = ../../users/krit/src/profile-picture/face-512.jpg;
        };
        impermanence.enable = true;
        nix-topology.enable = false;
        tailscale.enable = true;

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

        hypridle = {
          enable = true;
          dimTimeout = 900;
          lockTimeout = 1800;
          screenOffTimeout = 3600;
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
        krokiet.enable = true;
        librewolf.enable = true;
        neovim.enable = true;
        pwas.enable = true;
        ranger.enable = false;
        yazi.enable = true;
        zathura.enable = true;
      };


      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.desktop = {
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
        desktop-borg-backup.enable = true;
        owncloud.enable = false;
        smb.enable = true;
        sshfs.enable = false;
      };

      # ---------------------------------------------------------------
      # 🎭 SHARED SPECIALIZATIONS
      # -----------
      specializations = {
        guest.enable = true;
      };

      # ---------------------------------------------------------------
      # 🎭 KRIT SPECIALIZATIONS
      # ---------------------------------------------------------------
      krit.specializations = {
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
        virtualisation.enable = false;
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

