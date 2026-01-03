{
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
{
  # Import the Caelestia Home Manager module
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf (vars.caelestia or false) {

    # 1. Enable the Caelestia Shell (Widgets/Bar/Dashboard)
    programs.caelestia = {
      enable = true;
      cli.enable = true; # Adds the 'caelestia' command for controlling the shell

      # Optional settings found in README
      systemd.enable = false;
    };

    xdg.configFile."quickshell" = {
      source = inputs.caelestia-shell;
      recursive = true;
    };

    # 2. Hyprland Logic (Keep this from before)
    # We enable the binary but block the config generation so you can use Caelestia's hyprland.conf
    wayland.windowManager.hyprland.enable = true;
    xdg.configFile."hypr/hyprland.conf" = {
      enable = true;
      force = true; # 🟢 Add this to force overwriting the default config
    };

    home.sessionVariables = {
      # This tells Quickshell where to find the Caelestia QML modules
      QML2_IMPORT_PATH = "$HOME/.config/quickshell";
    };

    # 3. Dependencies
    home.packages = with pkgs; [
      # Standard Caelestia Deps
      hyprpicker
      wl-clipboard
      cliphist
      inotify-tools
      trash-cli
      jq
      eza
      foot
      fish
      fastfetch
      starship
      btop
      wireplumber
      adw-gtk3
      papirus-icon-theme
      libsForQt5.qt5ct
      kdePackages.qt6ct
      nerd-fonts.jetbrains-mono
      inputs.quickshell.packages.${pkgs.system}.default

      # NOTE: We removed 'inputs.quickshell...' here because
      # 'programs.caelestia.enable = true' installs it automatically.
    ];

    programs.fish.enable = true;
  };
}
