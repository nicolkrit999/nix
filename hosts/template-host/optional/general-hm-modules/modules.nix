{
  # ---------------------------------------------------------------------------
  # 🖥️ HYPRLAND WORKSPACES (Optional)
  # ---------------------------------------------------------------------------
  # Bind workspaces to monitors.
  # hyprlandWorkspaces = [
  #   "1, monitor:DP-1"
  #   "2, monitor:DP-2"
  # ];

  # Forces specific apps to always open on specific workspaces
  # To see the right class name, use `hyprctl clients` command and look for "class:"
  # hyprlandWindowRules = [
  #  "workspace 2, class:^(code)$"
  #  "workspace 7, class:^(chromium-browser)$"
  #  "workspace 8, class:^(Alacritty)$"
  #  "workspace 8, class:^(kitty)$"
  #  "workspace 9, class:^(vesktop)$"
  #  "workspace 10, class:^(org.telegram.desktop)$"
  # ];

  #hyprlandExtraBinds = [
  # SCRATCHPAD APPLICATIONS
  #   "$mainMod SHIFT, return, exec, [workspace special:magic] $term --class scratch-term"
  #  "$mainMod SHIFT, F, exec, [workspace special:magic] $term --class scratch-fs -e yazi"
  # "$mainMod SHIFT, B, exec, [workspace special:magic] ${rawVars.browser} --new-window --name scratch-browser"

  # EXTRA APPLICATION LAUNCHERS
  #"$mainMod,       Y, exec, chromium-browser"
  #];

  #gnomeExtraBinds = [
  # {
  #  name = "Launch Chromium";
  # command = "chromium";
  #binding = "<Super>y";
  #}
  #];

  # KDE: Attribute set (unique ID = { name, key, command })
  #kdeExtraBinds = {
  # "launch-chromium" = {
  #  key = "Meta+Y";
  # command = "chromium";
  # };
  # };

  # ---------------------------------------------------------------------------
  # 🖱️ KDE INPUT DEVICES (Optional)
  # ---------------------------------------------------------------------------
  # Specific mouse settings.
  # kdeMice = [
  #   {
  #     enable = true;
  #     name = "Logitech G403";
  #     vendorId = "046d";
  #     productId = "c08f";
  #     acceleration = -1.0;
  #     accelerationProfile = "none";
  #   }
  # ];

  # kdeTouchpads = [];

  # ---------------------------------------------------------------------------
  # 🧩 WAYBAR SETTINGS (Optional)
  # ---------------------------------------------------------------------------
  # waybarWorkspaceIcons = {
  #   "1" = ""; # empty (no icon)
  #   "2" = ":"; # Browser
  # };

  # waybarLayoutFlags = {
  #   "format-en" = "🇺🇸";
  # };

  # starshipZshIntegration = true;

  # nixImpure = false;

  #caelestiaUseFahrenheit = false;
}
