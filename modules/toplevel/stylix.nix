{ delib
, pkgs
, lib
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };

  # ===========================================================================
  # DARWIN STYLIX CONFIGURATION
  # ===========================================================================
  darwin.always =
    { myconfig, ... }:
    {
      imports = [
        inputs.stylix.darwinModules.stylix
      ];

      stylix = {
        enable = true;
        autoEnable = true;
        polarity = myconfig.constants.theme.polarity or "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme or "nord"
        }.yaml";

        opacity = {
          applications = 1.0;
          terminal = 0.90;
          desktop = 1.0;
          popups = 1.0;
        };

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          serif = {
            package = pkgs.noto-fonts;
            name = "Noto Serif";
          };
          sizes = {
            applications = 12;
            terminal = 14;
            desktop = 12;
            popups = 10;
          };
        };
      };
    };

  # ===========================================================================
  # NIXOS STYLIX CONFIGURATION
  # ===========================================================================
  nixos.always =
    { ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        inputs.catppuccin.nixosModules.catppuccin
      ];
    };

  home.always =
    { ... }:
    {
      # Only import stylix home module for standalone home-manager builds
      # For NixOS/Darwin, the system-level module handles home-manager integration
      imports = lib.optionals (moduleSystem == "home") [
        inputs.stylix.homeModules.stylix
        inputs.catppuccin.homeModules.catppuccin
      ]
      # For darwin, we need catppuccin home module since darwin.always doesn't import it
      ++ lib.optionals (moduleSystem == "darwin") [
        inputs.catppuccin.homeModules.catppuccin
      ];
    };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
    in
    {
      stylix = {
        enable = true;
        polarity = myconfig.constants.theme.polarity or "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme or "catppuccin-mocha"
        }.yaml";
        image = pkgs.fetchurl {
          url = fallbackWp.wallpaperURL;
          sha256 = fallbackWp.wallpaperSHA256;
        };

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
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";

      # NixOS-specific wallpaper logic (darwin doesn't have wallpapers constant)
      hasWallpapers = myconfig.constants ? wallpapers && myconfig.constants.wallpapers != [ ];
      fallbackWp = if hasWallpapers then
        lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers
      else
        null;

      hyprlandEnabled = myconfig.programs.hyprland.enable or false;
      caelestiaEnabled = myconfig.programs.caelestia.enableOnHyprland or false;
      noctaliaEnabled = myconfig.programs.noctalia.enableOnHyprland or false;
      useHyprpaper = hyprlandEnabled && !caelestiaEnabled && !noctaliaEnabled;
    in
    {
      stylix = lib.mkMerge [
        # NixOS-specific stylix settings (wallpaper)
        (lib.mkIf (isNixOS && hasWallpapers) {
          enable = true;
          image = pkgs.fetchurl {
            url = fallbackWp.wallpaperURL;
            sha256 = fallbackWp.wallpaperSHA256;
          };
          base16Scheme = "${pkgs.base16-schemes}/share/themes/${
            myconfig.constants.theme.base16Theme or "catppuccin-mocha"
          }.yaml";
        })

        # Shared stylix targets (both NixOS and Darwin)
        {
          targets = {
            neovim.enable = false;
            bat.enable = !isCatppuccin;
            lazygit.enable = !isCatppuccin;
            starship.enable = !isCatppuccin;
          }
          # NixOS-specific targets
          // lib.optionalAttrs isNixOS {
            wofi.enable = false;
            waybar.enable = false;
            hyprpaper.enable = lib.mkForce (!isCatppuccin && useHyprpaper);
            kde.enable = false;
            qt.enable = false;
            gnome.enable = myconfig.programs.gnome.enable or false;
            hyprland.enable = !isCatppuccin;
            hyprlock.enable = !isCatppuccin;
            gtk.enable = !isCatppuccin;
            swaync.enable = !isCatppuccin;
            tmux.enable = !isCatppuccin;
          }
          // cfg.targets;
        }
      ];

      # NixOS-specific dconf settings
      dconf.settings = lib.mkIf isNixOS {
        "org/gnome/desktop/interface".color-scheme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then "prefer-dark" else "prefer-light";
      };

      # NixOS-specific GTK theme settings
      home.sessionVariables = lib.mkIf (isNixOS && isCatppuccin) {
        GTK_THEME = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
          myconfig.constants.theme.catppuccinAccent or "mauve"
        }-standard+rimless,black";
        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkIf (isNixOS && isCatppuccin) {
        enable = true;
        theme = {
          package = pkgs.catppuccin-gtk.override {
            accents = [ (myconfig.constants.theme.catppuccinAccent or "mauve") ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = myconfig.constants.theme.catppuccinFlavor or "mocha";
          };
          name = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
            myconfig.constants.theme.catppuccinAccent or "mauve"
          }-standard+rimless,black";
        };
        gtk3.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
        gtk4.extraConfig.gtk-application-prefer-dark-theme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then 1 else 0;
      };
    };
}
