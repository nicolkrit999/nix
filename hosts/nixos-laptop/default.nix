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

  # 🌟 HYPRLAND APP WORKSPACES
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
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-laptop";
        mainLocale = myLocale;

        homeStateVersion = "25.11";

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

          /*
          # Commented out as it matches the fallbacks
          cursorStyle = "block";
          cursorBlink = true;
          cursorBeamWidth = 3.0;
          animation = true;
          */
        };
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        wallpapers = [

          {
            targetMonitor = "eDP-1";
            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/AngelJumbo/gruvbox-wallpapers/gruvbox-wallpapers-main/wallpapers/anime/Kurumi-Ebisuzawa.png";
            wallpaperSHA256 = "1rn290hx0vl70w1dvksqrp8n713zyswc0gm98zsh962nw9jrkmrk";
            gifURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/fr0st-xyz/wallz/wallz-main/Animated/06.%20Animated.gif";
            gifSHA256 = "1pl466cmnsp5hhxlz8z7kd3r7zdr365wwx94l9g1sf48fy0bv0qb";
          }
          {
            targetMonitor = "*";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/b56bc78bf5861f9d39afd2592ad572013dff6146/wallpapers/Pictures/wallpapers/various/other-user-github-repos/adarsh-67r-catppuccin-mocha-walls-main/space.png";
            wallpaperSHA256 = "1bnyvwgic8j830034rn1lwdky9fmz0y9k01iv5jnkpskfi0w7vci";
          }
        ];

        # ---------------------------------------------------------------
        # 🎨 THEMING
        # ---------------------------------------------------------------
        theme = {
          polarity = "dark";
          base16Theme = "catppuccin-mocha";
          catppuccin = true;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "mauve";
        };

        # ---------------------------------------------------------------
        # 🪟 HYPRLAND CONSTANTS
        # ---------------------------------------------------------------
        /*
          # Commented out as it matches the fallbacks
        hyprland = {
          rounding = 10;
          gap = 5;
          borderSize = 2;
          terminalOpacity = 0.9;
        };
        */

        # ---------------------------------------------------------------
        # 🌀 NIRI CONSTANTS
        # ---------------------------------------------------------------
        /*
        # Commented out as it matches the fallbacks
        niri = {
          gap = 8;
          rounding = 10;
        };
        */

        /*
        # Commented out as it matches the fallbacks
        screenshots = "$HOME/Pictures/Screenshots";
        keyboardLayout = "us";
        */
        keyboardVariant = "intl";

        weather = "Lugano";

        /*
        # Commented out as it matches the fallbacks
        useFahrenheit = false;
        nixImpure = false;
        */

        timeZone = "Europe/Zurich";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth = {
        enable = true;
        autoEnableOnBoot = false;
      };

      cachix = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/cachix-push-token";
      };

      krit.attic = {
        enable = true;
        push = true;
        authTokenPath = "/run/secrets/attic-push-token";
      };

      krit.commonSopsSecrets.enable = true;

      home-packages.enable = true;
      mime.enable = true;

      nh = {
        enable = true;
        gcd = "15d";
        gcn = "5";
      };
      nix-sweeps = {
        enable = true;
        gcd = "15d";
        gcn = "5";
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
        cava.enable = false;
        claude-desktop.enable = true;
        codex.enable = true;
        comma.enable = true;
        concord.enable = true;
        doom.enable = true;
        eza.enable = true;
        fzf.enable = true;
        fzf.nix-search-tv.enable = true;
        gnome-keyring.enable = true;
        google-antigravity.enable = true;
        lazygit.enable = true;
        nix-alien.enable = false;
        nix-topology.enable = false;
        nltchNur = {
          enable = false;
          packages = [ ];
          permittedInsecurePackages = [ ];
        };
        spotifyAdblock.enable = true;
        nix-ld.enable = false;
        npm = {
          enable = true;
          packages = [
            "claudefm" # terminal music player
            "claude-token-counter" # Token usage counter for claude code
            "@actual-app/cli" # Actual Budget CLI
          ];
          hostPackages = with pkgs; [
            yt-dlp # claudefm: stream source
            mpv # claudefm: playback
          ];
        };
        shell-aliases.enable = true;
        starship.enable = true;
        statix.enable = false;
        swayosd.enable = true;
        tgt.enable = true;
        tmux.enable = true;
        television.enable = true;
        walker.enable = false;
        waypaper.enable = false;
        zoxide.enable = true;
        zen.browser.enable = true;

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
            power-profile
            process-manager
            pulseaudio
            ssh
            supergenpass
            # systemd
            wifi-commander
            wikipedia
            zoxide-recent-directories
          ];
          extraRayCastExtensions = [
            { name = "downloads-manager"; hash = "sha256-GNEWSFWOsS7Ks0nPgqZrFqIYwdw1CYgswIhgAumvTOc="; }
            { name = "gif-search"; hash = "sha256-aWIYh6tQbdZxT04TRVEc/HmgJUXFl0eMFpIZpCaIQ4U="; }
            { name = "google-search"; hash = "sha256-nGTMIrSEgZX+gPpNc0tLme0MprVzA3Ap4gvEnq3n6IU="; }
            { name = "lorem-ipsum"; hash = "sha256-zMhwb4imj79XByXbbVHqhQxso9Jj87bBuJNbqwEjMxs="; }
            { name = "notion"; hash = "sha256-4ot/xa7PcwXB0ImsSyXBo3SXwfJgBlA0OLEv9HMYiO0="; }
            { name = "remove-paywall"; hash = "sha256-i0jPsCbkl9X/Ka2fRYFHxk3COPxP8V+2C3dTdg6118c="; }
            { name = "google-translate"; installName = "translate"; hash = "sha256-VhJ9wRnToUPccVIQwp4nxQ2ExkgukZIqqET5tS4RpfI="; }
            { name = "video-downloader"; hash = "sha256-/Q9VW59t4xgQROuumw/6DWENAWqada+GHszvMyVrT0w="; }
            { name = "visual-studio-code-recent-projects"; installName = "visual-studio-code"; hash = "sha256-fhTmPfLoFpU2wuPHlL0WlLqtHBCLJ7/VMKjt3wLewQc="; }
          ];
          extraPackages = with pkgs; [
            aria2 # Required by aria2-manager extension
          ];
        };

        headroom.enable = true;

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
            { sopsSecret = "claude_mcp_sparkyfitness_api_key"; envVar = "SPARKYFITNESS_API_KEY"; }
            #{ sopsSecret = "claude_mcp_kagi_api_key"; envVar = "KAGI_API_KEY"; }
          ];
          mcpEnv = {
            ACTUAL_SERVER_URL = "https://budget.nicolkrit.ch";
          };
        };


        git = {
          enable = true;
          customGitIgnores = [ ];
        };


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
            { output = "eDP-1"; mode = "3200x2000@120"; position = "0x0"; scale = 1.6; }
            { output = ""; mode = "preferred"; position = "auto"; scale = 1; }
          ];
          execOnce = [
            "hyprctl dispatch workspace 1"
            "[workspace 1 silent] ${myBrowser}"
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
            "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
          ];

          monitorWorkspaces = [
            { workspace = "1"; monitor = "eDP-1"; }
            { workspace = "2"; monitor = "eDP-1"; }
            { workspace = "3"; monitor = "eDP-1"; }
            { workspace = "4"; monitor = "eDP-1"; }
            { workspace = "5"; monitor = "eDP-1"; }
          ];

          windowRules = [
            { match.class = "^(${myEditor})$"; workspace = appWorkspaces.editor; }
            { match.class = "^(${myFileManager})$"; workspace = appWorkspaces.fileManager; }
            { match.class = "^(${myTerminal})$"; workspace = appWorkspaces.terminal; }
            { match.class = "^(code)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(nvim-editor)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(org.kde.kate)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(jetbrains-pycharm-ce)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(jetbrains-Clion)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(jetbrains-idea-ce)$"; workspace = "${appWorkspaces.editor} silent"; }
            { match.class = "^(org.kde.dolphin)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(thunar)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(yazi)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(ranger)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(org.gnome.Nautilus)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(nemo)$"; workspace = "${appWorkspaces.fileManager} silent"; }
            { match.class = "^(winboat)$"; workspace = "${appWorkspaces.vm} silent"; }
            { match.class = "^(Actual)$"; workspace = "${appWorkspaces.other} silent"; }
            { match.class = "^(org.jellyfin.JellyfinDesktop)$"; workspace = "${appWorkspaces.browser-Entertainment} silent"; }
            { match.class = "^(chromium-browser)$"; workspace = "${appWorkspaces.browser-Entertainment} silent"; }
            { match.class = "^(brave-browser)$"; workspace = "${appWorkspaces.browser-Entertainment} silent"; }
            { match.class = "^(brave-.*\\..*)$"; workspace = "${appWorkspaces.browser-Entertainment} silent"; }
            { match.class = "(?i)spotify"; workspace = "${appWorkspaces.browser-Entertainment} silent"; }
            { match.class = "^(kitty)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(alacritty)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(foot)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(xfce4-terminal)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(com.system76.CosmicTerm)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(org.kde.konsole)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(gnome-terminal)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(XTerm)$"; workspace = "${appWorkspaces.terminal} silent"; }
            { match.class = "^(vesktop)$"; workspace = "${appWorkspaces.chat} silent"; }
            { match.class = "^(org.telegram.desktop)$"; workspace = "${appWorkspaces.chat} silent"; }
            { match.class = "^(whatsapp-electron)$"; workspace = "${appWorkspaces.chat} silent"; }
            { match.class = "^(com.rtosta.zapzap)$"; workspace = "${appWorkspaces.chat} silent"; }

            { match.class = "^(scratch-term)$"; float = true; }
            { match.class = "^(scratch-term)$"; center = true; }
            { match.class = "^(scratch-term)$"; size = "80% 80%"; }
            { match.class = "^(scratch-term)$"; workspace = "special:magic"; }
            { match.class = "^(scratch-fs)$"; float = true; }
            { match.class = "^(scratch-fs)$"; center = true; }
            { match.class = "^(scratch-fs)$"; size = "80% 80%"; }
            { match.class = "^(scratch-fs)$"; workspace = "special:magic"; }
            { match.class = "^(scratch-browser)$"; float = true; }
            { match.class = "^(scratch-browser)$"; center = true; }
            { match.class = "^(scratch-browser)$"; size = "80% 80%"; }
            { match.class = "^(scratch-browser)$"; workspace = "special:magic"; }

            { match.class = "^winboat-.*$"; workspace = appWorkspaces.vm; }
            { match.class = "^winboat-.*$"; suppress_event = "fullscreen maximize activate activatefocus"; }
            { match.class = "^winboat-.*$"; no_initial_focus = true; }
            { match.class = "^winboat-.*$"; no_anim = true; }
            { match.class = "^winboat-.*$"; rounding = 0; }
            { match.class = "^winboat-.*$"; no_shadow = true; }
            { match.class = "^winboat-.*$"; no_blur = true; }
            { match.class = "^winboat-.*$"; opaque = true; }
          ];

          extraBinds = [
            { _args = [ "SUPER + SHIFT + return" (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-term")'') ]; }
            { _args = [ "SUPER + SHIFT + F" (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-fs -e yazi")'') ]; }
            { _args = [ "SUPER + SHIFT + B" (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myBrowser} --new-window --class scratch-browser")'') ]; }

            { _args = [ "XF86Tools" (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m-1" })'') ]; }
            { _args = [ "XF86Launch5" (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m+1" })'') ]; }
            { _args = [ "XF86Launch6" (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()") ]; }
            { _args = [ "XF86Launch7" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
          ];
        };

        mango = {
          enable = true;
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
            "NONE,XF86Launch6,togglemaximizescreen,"
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
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 14 && flatpak run com.rtosta.zapzap'" # Sleep necessary to allow loading right polarity
            #"sh -c 'sleep 17 && protonvpn-app --start-minimized'"
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

        waybar-mango = {
          enable = true;
          waybarLayout = langLayout;
        };

        waybar-niri = {
          enable = true;
          waybarLayout = {
            "format-en" = "🇺🇸-EN";
          };
        };

        # ---------------------------------------------------------------
        # 🖥️ DESKTOP ENVIRONMENTS
        # ---------------------------------------------------------------
        cosmic = {
          enable = false;
        };

        gnome = {
          enable = false; # Gnome pulls lot of elements. Since i almost never use it keep it disabled to save battery and resources
          pinnedApps = pinnedApps;
          extraBinds = [
            # 🖱️ LOGITECH MX MASTER Thumb button gesstures
            { name = "Gesture Left (Prev Workspace)"; command = "${pkgs.wtype}/bin/wtype -M super -k Page_Up -m super"; binding = "XF86Tools"; }
            { name = "Gesture Right (Next Workspace)"; command = "${pkgs.wtype}/bin/wtype -M super -k Page_Down -m super"; binding = "XF86Launch5"; }
            { name = "Gesture Up (Maximize)"; command = "${pkgs.wtype}/bin/wtype -M super -k Up -m super"; binding = "XF86Launch6"; }
            { name = "Gesture Down (Close)"; command = "${pkgs.wtype}/bin/wtype -M super -M shift -k c -m shift -m super"; binding = "XF86Launch7"; }
          ];
        };

        kde = {
          enable = true;
          pinnedApps = pinnedApps;
          extraBinds = {
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
        audio.enable = true;
        autotrash.enable = true;
        external.dotfiles.enable = true;
        external.dotfiles-private.enable = true;
        hyprlock.enable = true;
        impermanence.enable = true;
        rcloneMount.enable = true;
        resolved.enable = true;
        tailscale.enable = true;

        # Power management (mutually exclusive - only enable ONE)
        auto-cpufreq.enable = false; # Recommended: dynamic CPU scaling (uses official flake)
        tlp.enable = false; # Alternative: static power policies (uses NixOS native)
        thermald.enable = false;

        hypridle = {
          enable = true;
          dimTimeout = 180;
          lockTimeout = 300;
          screenOffTimeout = 600;
        };

        sddm-astronaut = {
          enable = true;
          embeddedTheme = "jake_the_dog";
          background = ../../users/krit/src/wallpapers/car.gif;
        };
        sddm-pixie = {
          enable = false;
          avatar = ../../users/krit/src/profile-picture/face-512.jpg;
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

        swaync = {
          enable = true;
          customSettings = {
            /*
            "mute-protonvpn" = {
              state = "ignored";
              app-name = ".*Proton.*";
            */
          };
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs = {
        alacritty.enable = false;
        chromium.enable = false;
        claude-code-wrappers.enable = true;
        direnv.enable = true;
        dolphin.enable = true;
        firefox.enable = false;
        helium.enable = false;
        kitty.enable = true;
        krokiet.enable = true;
        librewolf.enable = false;
        neovim.enable = true;
        pwas.enable = true;
        proton-cli.enable = true;
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

      krit.services.cloud = {
        googleDrive.enable = true;
        onedrivePersonal.enable = true;
        pcloud.enable = true;
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
      # 🎭 KRIT SPECIALIZATIONS
      # ---------------------------------------------------------------
      krit.specializations = {
        entertainment.enable = false;
        home.enable = true;
        school.enable = true;
      };

      # ---------------------------------------------------------------
      # 🔧 KRIT SYSTEM
      # ---------------------------------------------------------------
      krit.system = {
        default-user.enable = true;
        git-ssh-signing.enable = true;
        swiss-locale.enable = true;
        ssh-config.enable = true;
        virtualisation.enable = true;
      };

      # ---------------------------------------------------------------
      # 🏠 KRIT HOME
      # ---------------------------------------------------------------
      krit.home.base.enable = true;
    };
}
