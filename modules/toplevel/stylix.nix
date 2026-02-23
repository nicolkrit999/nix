{ delib
, pkgs
, lib
, inputs
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
      imports = [ inputs.stylix.nixosModules.stylix ];
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

      hyprlandEnabled = myconfig.programs.hyprland.enable or false;
      caelestiaEnabled = myconfig.programs.caelestia.enableOnHyprland or false;
      noctaliaEnabled = myconfig.programs.noctalia.enableOnHyprland or false;

      useHyprpaper = hyprlandEnabled && !caelestiaEnabled && !noctaliaEnabled;
    in
    {
      stylix.targets = {
        neovim.enable = false;
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
        bat.enable = !isCatppuccin;
        lazygit.enable = !isCatppuccin;
        tmux.enable = !isCatppuccin;
        starship.enable = !isCatppuccin;
      }
      // cfg.targets;

      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme =
          if (myconfig.constants.theme.polarity or "dark") == "dark" then "prefer-dark" else "prefer-light";
      };

      home.sessionVariables = lib.mkIf isCatppuccin {
        GTK_THEME = "catppuccin-${myconfig.constants.theme.catppuccinFlavor or "mocha"}-${
          myconfig.constants.theme.catppuccinAccent or "mauve"
        }-standard+rimless,black";
        XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
      };

      gtk = lib.mkIf isCatppuccin {
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
