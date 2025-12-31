{
  pkgs,
  lib,
  inputs,
  config,
  vars,
  ...
}:
let
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;
  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  imports = [ inputs.stylix.homeModules.stylix ];

  home.packages = with pkgs; [
    dejavu_fonts # Classic fallback fonts
    noto-fonts-lgc-plus # For extended Latin, Greek, Cyrillic support
    texlivePackages.hebrew-fonts # For Hebrew script support
    font-awesome # Icon font used by Waybarpackage

    powerline-fonts # Required for shell prompts
    powerline-symbols # Required for shell prompts

    (catppuccin-gtk.override {
      # Force install the theme package
      accents = [ vars.catppuccinAccent ];
      size = "standard";
      tweaks = [
        "rimless"
        "black"
      ];
      variant = vars.catppuccinFlavor;
    })
  ];

  stylix = {
    enable = true;
    polarity = vars.polarity; # Sets a global preference for dark mode
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${vars.base16Theme}.yaml";
    image = pkgs.fetchurl {
      url = (builtins.head vars.wallpapers).wallpaperURL;
      sha256 = (builtins.head vars.wallpapers).wallpaperSHA256;
    };

    # -----------------------------------------------------------------------
    # 🎯 TARGETS (Exclusions)
    # -----------------------------------------------------------------------
    # Tells Stylix NOT to automatically skin these programs (except for Firefox).
    targets = {

      # It is possible to enable these, but it require manual theming in the modules/program itself
      neovim.enable = false; # Custom themed via my personal neovim stow config in dotfiles
      wofi.enable = false; # Themed manually via wofi/style.css

      # These should remain disabled because all edge cases are already handled
      waybar.enable = false; # Custom themed via waybar.nix using catppuccin nix https://github.com/catppuccin/nix/blob/95042630028d613080393e0f03c694b77883c7db/modules/home-manager/waybar.nix
      hyprpaper.enable = lib.mkForce false; # Wallpapers are handled manually in flake.nix and are hosts-specific

      # These should absolutely remain disabled because they cause conflicts
      kde.enable = false; # Needed to prevent stylix to override kde settings. Enabling this crash kde plasma session
      qt.enable = false; # Needed to prevent stylix to override qt settings. Enabling this crash kde plasma session

      # These should remain enabled to avoid conflicts with other modules (empty for now)

      # ---------------------------------------------------------------------------------------
      # 🎨 GLOBAL CATPPUCCIN
      # Intelligently enable/disable stylix based on whether catppuccin is enabled
      # catppuccin = true -> .enable = false
      # catppuccin = false -> .enable = true
      gtk.enable = !vars.catppuccin; # Avoid .gtkrc-2.0 and gtk-3.0 overrides
      alacritty.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/alacritty.nix
      hyprland.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/main.nix
      hyprlock.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/hyprlock.nix
      swaync.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/swaync/default.nix
      zathura.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/zathura.nix
      bat.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/bat.nix
      lazygit.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/lazygit.nix
      tmux.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/tmux.nix
      starship.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/starship.nix
      cava.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/cava.nix
      kitty.enable = !vars.catppuccin; # Ref: ~/nixOS/home-manager/modules/kitty.nix
      # ---------------------------------------------------------------------------------------

      # Enable stylix but only for certain elements
      firefox.profileNames = [ vars.user ]; # Applies skin only to the defined profile
    };

    # -----------------------------------------------------------------------
    # 🖱️ MOUSE CURSOR
    # -----------------------------------------------------------------------
    cursor = {
      name = "DMZ-Black";
      size = 24;
      package = pkgs.vanilla-dmz;
    };

    fonts = {
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
      monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sansSerif = {
        name = "Noto Sans";
        package = pkgs.noto-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      sizes = {
        terminal = 13;
        applications = 11;
      };
    };

    iconTheme = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
  };

  dconf.settings = lib.mkIf vars.catppuccin {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkForce (if vars.polarity == "dark" then "prefer-dark" else "prefer-light");
    };
  };

  home.sessionVariables = lib.mkIf vars.catppuccin {
    GTK_THEME = "catppuccin-${vars.catppuccinFlavor}-${vars.catppuccinAccent}-standard+rimless,black";

    XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
  };

  # 3. Configure GTK Theme &amp; Settings
  gtk = lib.mkIf vars.catppuccin {
    enable = true;

    theme = {
      package = lib.mkForce (
        pkgs.catppuccin-gtk.override {
          accents = [ vars.catppuccinAccent ];
          size = "standard";
          tweaks = [
            "rimless"
            "black"
          ];
          variant = vars.catppuccinFlavor;
        }
      );
      name = lib.mkForce "catppuccin-${vars.catppuccinFlavor}-${vars.catppuccinAccent}-standard+rimless,black";
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = if vars.polarity == "dark" then 1 else 0;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = if vars.polarity == "dark" then 1 else 0;
  };
}
