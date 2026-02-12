{ lib
, pkgs
, vars
, ...
}:
let
  # Allow to use variables despite flake.nix use this to create variables
  rawVars = import ../../variables.nix;

  # Keep 1 and 6 free
  # keyboard key 0 = 10
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    other = "5";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
  };

  desktopMap = {
    # Browsers
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "chromium" = "chromium-browser.desktop"; # Found in user-apps.txt
    "brave" = "brave-browser.desktop";

    # Editors
    "nvim" = "custom-nvim.desktop"; # Standard package provides this
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";

    # File Managers
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "Nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };

  resolve = name: desktopMap.${name} or "${name}.desktop";
in
{
  # ---------------------------------------------------------------------------
  # 🖥️ HYPRLAND WORKSPACES
  # ---------------------------------------------------------------------------
  hyprlandWorkspaces = [
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

  # Forces specific apps to always open on specific workspaces (0.53.0 Format)
  hyprlandWindowRules = [
    # Editor Workspace
    "workspace ${appWorkspaces.editor} silent, match:class:^(code|nvim-editor|org.kde.kate|jetbrains-pycharm-ce|jetbrains-Clion|jetbrains-idea-ce)$"

    # FileManager Workspace
    "workspace ${appWorkspaces.fileManager} silent, match:class:^(org.kde.dolphin|thunar|yazi|ranger|org.gnome.Nautilus|nemo)$"

    # Virtual Machines
    "workspace ${appWorkspaces.vm} silent, match:class:^(winboat)$"

    # Browsers / Entertainment
    "workspace ${appWorkspaces.browser-Entertainment} silent, match:class:^(chromium-browser|brave-browser|brave-.*)$"

    # Terminals
    "workspace ${appWorkspaces.terminal} silent, match:class:^(kitty|alacritty|foot|xfce4-terminal|com.system76.CosmicTerm|org.kde.konsole|gnome-terminal|XTerm)$"

    # Chat
    "workspace ${appWorkspaces.chat} silent, match:class:^(vesktop|org.telegram.desktop|whatsapp-electron)$"

    # Scratchpad Rules (Magic Workspace)
    "float, match:class:^(scratch-term|scratch-fs|scratch-browser)$"
    "center, match:class:^(scratch-term|scratch-fs|scratch-browser)$"
    "size 80% 80%, match:class:^(scratch-term|scratch-fs|scratch-browser)$"
    "workspace special:magic, match:class:^(scratch-term|scratch-fs|scratch-browser)$"

    # --- WINBOAT SUB-APP RULES (0.53 Strict) ---
    "workspace ${appWorkspaces.vm}, match:class:^winboat-.*$"
    "suppressevent fullscreen maximize activate activatefocus, match:class:^winboat-.*$"
    "noinitialfocus = on, match:class:^winboat-.*$"
    "noanim = on, match:class:^winboat-.*$"
    "norounding = on, match:class:^winboat-.*$"
    "noshadow = on, match:class:^winboat-.*$"
    "noblur = on, match:class:^winboat-.*$"
    "opaque = on, match:class:^winboat-.*$"
  ];

  hyprlandExtraBinds = [
    # SCRATCHPAD APPLICATIONS
    "$Mod SHIFT, return, exec, [workspace special:magic] $term --class scratch-term"
    "$Mod SHIFT, F, exec, [workspace special:magic] $term --class scratch-fs -e yazi"
    "$Mod SHIFT, B, exec, [workspace special:magic] ${rawVars.browser} --new-window --class scratch-browser"

    # EXTRA APPLICATION LAUNCHERS
    "$Mod,       Y, exec, chromium-browser"
  ];

  gnomeExtraBinds = [
    {
      name = "Launch Chromium";
      command = "chromium";
      binding = "<Super>y";
    }
  ];

  # KDE: Attribute set (unique ID = { name, key, command })
  kdeExtraBinds = {
    "launch-chromium" = {
      key = "Meta+Y";
      command = "chromium";
    };
  };

  # ---------------------------------------------------------------------------
  # 🖱️ KDE INPUT DEVICES
  # ---------------------------------------------------------------------------
  # Strict hardware IDs for Plasma Manager.
  # If you remove this, KDE will use default plug-and-play settings.
  # Commented because i have 2 logitech mouse connected
  /*
    kdeMice = [
      {
        enable = true;
        name = "Logitech G403";
        vendorId = "046d"; # Logitech
        productId = "c08f"; # G403
        acceleration = -1.0;
        accelerationProfile = "none";
      }
    ];
  */

  # Leave empty for desktop PCs
  #kdeTouchpads = [ ];

  # ---------------------------------------------------------------------------
  # 🧩 WAYBAR WORKSPACE ICONS
  # ---------------------------------------------------------------------------
  # Define custom icons for specific workspace numbers.
  # If you remove this, Waybar will just show numbers (1, 2, 3...)
  waybarWorkspaceIcons = {
    "1" = "";
    "2" = "";
    "3" = "";
    "4" = "";
    "5" = "";
    "6" = "";
    "7" = ":"; # Chrome/Browser
    "8" = ":"; # Terminal
    "9" = ":"; # Music
    "10" = ":"; # Chat
    "magic" = ":"; # Scratchpad
  };

  waybarLayout = {
    "format-en" = "🇺🇸-EN";
    "format-it" = "🇮🇹-IT";
    "format-de" = "🇩🇪-DE";
    "format-fr" = "🇫🇷-FR";
  };

  hyprland_Exec-Once = [
    # Personal apps based on variables
    "uwsm app -- $term"
    "sleep 2 && uwsm app -- $browser"
    "uwsm app -- $editor"
    "uwsm app -- $fileManager"

    # Secondary apps
    "sleep 4 && uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
    "whatsapp-electron"

    # Opened minimized
    #"sleep 5 && protonvpn-app --start-minimized"

    # System tweaks
  ];

  niri_Exec-Once = [
    # Personal apps
    "${vars.browser}"
    "${vars.editor}"
    "${vars.fileManager}"
    "${vars.term}"

    # Secondary apps
    "chromium-browser"
    # "sleep 5 && protonvpn-app --start-minimized"
  ];

  stylixExclusions = {
    # Strictly false
    yazi.enable = false;

    # Strictly true
    cava.enable = true;

    # Catppuccin variable-based
    kitty.enable = !vars.catppuccin;
    alacritty.enable = !vars.catppuccin;
    zathura.enable = !vars.catppuccin;

    # Other
    firefox.profileNames = [ vars.user ];
    librewolf.profileNames = [
      "default"
      "privacy"
    ];
  };

  swayncExclusions = {
    "mute-protonvpn" = {
      state = "ignored";
      app-name = ".*Proton.*";
    };
  };

  pinnedApps = [
    (resolve vars.browser)
    (resolve vars.editor)
    (resolve vars.fileManager)

    # Regular app
    "github-desktop.desktop"
    "LocalSend.desktop"
    "proton-pass.desktop"
    "vesktop.desktop"

    # Flatpaks
    "com.github.dagmoller.whatsapp-electron.desktop"
    "com.actualbudget.actual.desktop"
  ];

  customGitIgnores = [ ];

  nixImpure = false;

  useFahrenheit = false;

}
