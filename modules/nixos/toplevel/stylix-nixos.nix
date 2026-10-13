{ delib
, pkgs
, lib
, config
, inputs
, moduleSystem
, ...
}:
let
  look = myconfig: {
    polarity = myconfig.constants.theme.polarity;
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
        name = "JetBrainsMono Nerd Font Propo";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      # JetBrains has no serif face, so serif uses the proportional variant too
      serif = {
        name = "JetBrainsMono Nerd Font Propo";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sizes = {
        terminal = 11;
        applications = 11;
      };
    };
  };
in
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };

  nixos.always =
    { ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];
    };

  home.always =
    { ... }:
    {
      imports = lib.optionals (moduleSystem == "home") [
        inputs.stylix.homeModules.stylix
      ];
    };

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      primaryWp = myconfig.constants.primaryWallpaper;
    in
    {
      stylix = {
        enable = true;
        inherit (look myconfig) polarity cursor fonts;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme
        }.yaml";
        image = pkgs.fetchurl {
          url = primaryWp.wallpaperURL;
          sha256 = primaryWp.wallpaperSHA256;
        };
      };
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      sansFont = config.stylix.fonts.sansSerif;
      monoFont = config.stylix.fonts.monospace;
      appFontSize = config.stylix.fonts.sizes.applications;
      isCatppuccin = myconfig.constants.theme.catppuccin;
      polarity = myconfig.constants.theme.polarity;
      preferDark = if polarity == "dark" then 1 else 0;
      gtkThemeName = "catppuccin-${myconfig.constants.theme.catppuccinFlavor}-${
        myconfig.constants.theme.catppuccinAccent
      }-standard+rimless,black";
      catppuccinGtkTheme = {
        package = pkgs.catppuccin-gtk.override {
          accents = [ myconfig.constants.theme.catppuccinAccent ];
          size = "standard";
          tweaks = [
            "rimless"
            "black"
          ];
          variant = myconfig.constants.theme.catppuccinFlavor;
        };
        name = gtkThemeName;
      };
      primaryWp = myconfig.constants.primaryWallpaper;
    in
    {
      stylix = {
        enable = true;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme
        }.yaml";
        image = pkgs.fetchurl {
          url = primaryWp.wallpaperURL;
          sha256 = primaryWp.wallpaperSHA256;
        };
        targets = lib.recursiveUpdate
          {
            neovim.enable = false;
            bat.enable = !isCatppuccin;
            lazygit.enable = !isCatppuccin;
            starship.enable = !isCatppuccin;
            wofi.enable = false;
            rofi.enable = false;
            waybar.enable = false;
            kde.enable = !isCatppuccin;
            qt.enable = false;
            gnome.enable = false;
            hyprland.enable = !isCatppuccin;
            hyprlock.enable = !isCatppuccin;
            gtk.enable = !isCatppuccin;
            swaync.enable = !isCatppuccin;
            tmux.enable = !isCatppuccin;
            gtksourceview.enable = false; # Could cause slow-downs during rebuilds. See "https://github.com/nix-community/stylix/discussions/2232#discussion-9598872"
          }
          cfg.targets;
      } // lib.optionalAttrs (moduleSystem == "home") (look myconfig);

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = if polarity == "dark" then "prefer-dark" else "prefer-light";
      } // lib.optionalAttrs isCatppuccin {
        font-name = "${sansFont.name} ${toString appFontSize}";
        document-font-name = "${sansFont.name} ${toString appFontSize}";
        monospace-font-name = "${monoFont.name} ${toString appFontSize}";
      };

      home.packages = lib.optionals isCatppuccin [ sansFont.package monoFont.package ];
      fonts.fontconfig.enable = lib.mkIf isCatppuccin true;

      home.sessionVariables = lib.mkIf isCatppuccin {
        GTK_THEME = gtkThemeName;
        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkMerge [
        (lib.mkIf isCatppuccin {
          enable = true;
          theme = catppuccinGtkTheme;
          font = {
            inherit (sansFont) name package;
            size = appFontSize;
          };
        })
        {
          gtk3.extraConfig.gtk-application-prefer-dark-theme = preferDark;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = preferDark;
          gtk4.theme = lib.mkIf isCatppuccin catppuccinGtkTheme;
        }
      ];
    };
}
