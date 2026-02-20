{
  delib,
  inputs,
  pkgs,
  lib,
  input,
  ...
}:
delib.module {
  name = "stylix";

  # Define the schema to catch your host's exclusions!
  options.stylix = with delib; {
    enable = boolOption true;
    targets = attrsOption { };
  };

  home.ifEnabled =
    {

      cfg,
      myconfig,
      ...
    }:
    let
      # If the variable is missing given the ! then the default is "true"
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        polarity = myconfig.constants.theme.polarity; # Sets a global preference for dark mode
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${myconfig.constants.base16Theme}.yaml";
        image = pkgs.fetchurl {
          url = (builtins.head myconfig.constants.wallpapers).wallpaperURL;
          sha256 = (builtins.head myconfig.constants.wallpapers).wallpaperSHA256;
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
          gnome.enable = myconfig.programs.gnome.enable or false;

          # These should remain enabled to avoid conflicts with other modules
          # N/A

          # ---------------------------------------------------------------------------------------
          # 🎨 GLOBAL CATPPUCCIN
          # Intelligently enable/disable stylix based on whether catppuccin is enabled
          # catppuccin = true -> .enable = false
          # catppuccin = false -> .enable = true
          hyprland.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/main.nix

          hyprlock.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/hyprland/hyprlock.nix

          gtk.enable = !isCatppuccin; # No ref

          swaync.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/swaync/default.nix

          bat.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/bat.nix

          lazygit.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/lazygit.nix

          tmux.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/tmux.nix

          starship.enable = !isCatppuccin; # Ref: ~/nixOS/home-manager/modules/starship.nix

        }
        // (myconfig.constants.stylixExclusions or { });

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
      };

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme =
            if myconfig.constants.theme.polarity == "dark" then "prefer-dark" else "prefer-light";
        };
      };

      home.sessionVariables = lib.mkIf (myconfig.constants.theme.catppuccin or false) {
        # Fallback to mocha/mauve if flavor/accent are missing
        GTK_THEME = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
          myconfig.constants.theme.catppuccinAccent or "mauve"
        }-standard+rimless,black";

        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkIf (myconfig.constants.theme.catppuccin or false) {
        enable = true;
        theme = {
          package = lib.mkForce (
            pkgs.catppuccin-gtk.override {
              accents = [ (myconfig.constants.theme.catppuccinAccent or "mauve") ];
              size = "standard";
              tweaks = [
                "rimless"
                "black"
              ];
              variant = myconfig.constants.theme.catppuccinFlavor or "mocha";
            }
          );
          # Fallback values for the theme name string
          name = lib.mkForce "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
            myconfig.constants.theme.catppuccinAccent or "mauve"
          }-standard+rimless,black";
        };
        # 🌙 Fallback to dark mode (1) if myconfig.constants.theme.polarity is missing
        gtk3.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
        gtk4.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
      };
    };
}
