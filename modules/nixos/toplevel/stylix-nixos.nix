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

  nixos.always =
    { ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      # Stylix's gnome NixOS module (pinned to 25.11) sets the renamed-in-26.05 option
      # `services.displayManager.environment`, producing a noisy eval warning even when
      # gnome isn't enabled (the rename module fires regardless of mkIf gating). We don't
      # use GNOME on any active host, so drop the module entirely. Re-enable + drop this
      # line if stylix ships release-26.05 OR if a host starts using GNOME.
      disabledModules = [ "${inputs.stylix}/modules/gnome/nixos.nix" ];
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
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
    in
    {
      # Mirror enableReleaseChecks=false into every HM user so the home-manager-side
      # stylix module also stops complaining about the 25.11 vs 26.05 version mismatch.
      home-manager.sharedModules = [{ stylix.enableReleaseChecks = false; }];

      stylix = {
        enable = true;
        # Suppress release-mismatch warning: stylix is intentionally pinned to release-25.11
        # while the rest of the system is on 26.05 (no stylix release-26.05 branch yet as of 2026-05-30).
        enableReleaseChecks = false;
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
      polarity = myconfig.constants.theme.polarity or "dark";
      catppuccinGtkTheme = {
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
      hasWallpapers = myconfig.constants ? wallpapers && myconfig.constants.wallpapers != [ ];
      fallbackWp =
        if hasWallpapers then
          lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers
        else
          null;

    in
    {
      stylix = lib.mkMerge [
        (lib.mkIf hasWallpapers {
          enable = true;
          image = pkgs.fetchurl {
            url = fallbackWp.wallpaperURL;
            sha256 = fallbackWp.wallpaperSHA256;
          };
          base16Scheme = "${pkgs.base16-schemes}/share/themes/${
            myconfig.constants.theme.base16Theme or "catppuccin-mocha"
          }.yaml";
        })

        {
          targets = {
            neovim.enable = false;
            bat.enable = !isCatppuccin;
            lazygit.enable = !isCatppuccin;
            starship.enable = !isCatppuccin;
            wofi.enable = false;
            waybar.enable = false;
            # Drive kdeglobals palette + colorscheme file from base16. Works on
            # any DE/WM combo — fixes Dolphin / KDE FileChooser portal zebra.
            # Writes to xdg.systemDirs.config so plasma-manager's overrideConfig
            # cannot wipe it.
            kde.enable = !isCatppuccin;
            # Intentionally false: stylix.targets.qt forces
            # qt.platformTheme.name = "qtct", which strips plasma-integration
            # from Plasma's own widgets and crashes Plasma sessions. Qt theming
            # outside KDE is handled manually in modules/nixos/toplevel/qt.nix.
            qt.enable = false;
            # `gnome.enable` setting removed: stylix's gnome NixOS module is now disabled
            # via `disabledModules` above (it sets a renamed-in-26.05 option). Re-add this
            # line if/when the module is re-enabled.
            hyprland.enable = !isCatppuccin;
            hyprlock.enable = !isCatppuccin;
            gtk.enable = !isCatppuccin;
            swaync.enable = !isCatppuccin;
            tmux.enable = !isCatppuccin;
            gtksourceview.enable = false; # Could cause slow-downs during rebuilds. See "https://github.com/nix-community/stylix/discussions/2232#discussion-9598872"
          } // cfg.targets;
        }
      ];

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme =
          if polarity == "dark" then "prefer-dark" else "prefer-light";
      };

      home.sessionVariables = lib.mkIf isCatppuccin {
        GTK_THEME = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
          myconfig.constants.theme.catppuccinAccent or "mauve"
        }-standard+rimless,black";
        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkMerge [
        (lib.mkIf isCatppuccin {
          enable = true;
          theme = catppuccinGtkTheme;
        })
        # GTK3 dark preference needed by all apps including the GTK portal file picker
        # (xdg-desktop-portal-gtk = GTK3; cannot rely on color-scheme like GTK4/libadwaita).
        # GNOME 49 removed the gtk-application-prefer-dark-theme GSettings key, so we
        # write it directly into settings.ini via extraConfig.
        {
          gtk3.extraConfig.gtk-application-prefer-dark-theme = if polarity == "dark" then 1 else 0;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = if polarity == "dark" then 1 else 0;
        }
      ];
    };
}
