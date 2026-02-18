{
  lib,
  pkgs,
  vars,
  ...
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

  # Forces specific apps to always open on specific workspaces
  # To see the right class name, use `hyprctl clients` command and look for "class:"
  hyprlandWindowRules = [
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

    "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(chromium-browser)$"
    "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-music.apple.com.*)$"
    "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(vivaldi-music.apple.com.*)$"
    "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-browser)$"
    "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(vivaldi-www\.youtube\.com.*)$"
    #"workspace ${appWorkspaces.browser-Entertainment} silent, class:^(vivaldi-www.youtube.com)$"

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

    # Scratchpad rules - terminal
    "float, class:^(scratch-term)$"
    "center, class:^(scratch-term)$"
    "size 80% 80%, class:^(scratch-term)$"
    "workspace special:magic, class:^(scratch-term)$"

    # Scratchpad rules - file manager
    "float, class:^(scratch-fs)$"
    "center, class:^(scratch-fs)$"
    "size 80% 80%, class:^(scratch-fs)$"
    "workspace special:magic, class:^(scratch-fs)$"

    # Scratchpad rules - browser
    "float, class:^(scratch-browser)$"
    "center, class:^(scratch-browser)$"
    "size 80% 80%, class:^(scratch-browser)$"
    "workspace special:magic, class:^(scratch-browser)$"

    "workspace ${appWorkspaces.vm} silent, class:^(winboat)$"

    # --- WINBOAT SUB-APP RULES ---
    "workspace ${appWorkspaces.vm}, class:^winboat-.*$"
    "suppressevent fullscreen maximize activate activatefocus, class:^winboat-.*$"
    "noinitialfocus, class:^winboat-.*$"
    "noanim, class:^winboat-.*$"
    "norounding, class:^winboat-.*$"
    "noshadow, class:^winboat-.*$"
    "noblur, class:^winboat-.*$"
    "opaque, class:^winboat-.*$"
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
    "${vars.term}"
    "${vars.browser}"
    "uwsm app -- $editor"
    "uwsm app -- $fileManager"

    # Secondary apps
    "vivaldi --app=https://www.youtube.com"
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
