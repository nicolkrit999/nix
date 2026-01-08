let
  # Allow to use variables despite flake.nix use this to create variables
  rawVars = import ../../variables.nix;

  # Keep 1 and 6 free
  # keyboard key 0 = 10
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    browser = "7";
    terminal = "8";
    chat = "9";
  };
in
{
  # ---------------------------------------------------------------------------
  # 🖥️ HYPRLAND WORKSPACES
  # ---------------------------------------------------------------------------
  # Strict monitor bindings for my main PC.
  # If you remove this, Hyprland will auto-detect monitors based on mouse focus.
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

    "workspace ${appWorkspaces.browser} silent, class:^(chromium-browser)$"

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
  ];

  hyprlandExtraBinds = [
    # SCRATCHPAD APPLICATIONS
    "$mainMod SHIFT, return, exec, [workspace special:magic] $term --class scratch-term"
    "$mainMod SHIFT, F, exec, [workspace special:magic] $term --class scratch-fs -e yazi"
    "$mainMod SHIFT, B, exec, [workspace special:magic] ${rawVars.browser} --new-window --class scratch-browser"

    # EXTRA APPLICATION LAUNCHERS
    "$mainMod,       Y, exec, chromium-browser"
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

  # Leave empty for desktop PCs
  kdeTouchpads = [ ];

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
    "magic" = ":";
  };

  waybarLayoutFlags = {
    "format-en" = "🇺🇸";
    "format-it" = "🇮🇹";
    "format-de" = "🇩🇪";
    "format-fr" = "🇫🇷";
  };

  starshipZshIntegration = false;
  starshipFishIntegration = true;
  starshipBashIntegration = true;

  nixImpure = false;

  useFahrenheit = false;

}
