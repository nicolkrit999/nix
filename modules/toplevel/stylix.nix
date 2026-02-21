{
  delib,
  pkgs,
  lib,
  inputs,
  ...
}:
delib.module {
  name = "stylix";

  options.stylix = with delib; {
    enable = boolOption true;
    targets = attrsOption { };
  };

  # 🌟 1. NIXOS ALWAYS: Import the module globally (Unconditional)
  nixos.always =
    { ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];
    };

  # 🌟 2. NIXOS CONFIG: Global Stylix settings (Image, Polarity, Fonts)
  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      wallpapers = myconfig.constants.wallpapers or [ ];
      hasWallpaper = builtins.length wallpapers > 0;
      wallpaper =
        if hasWallpaper then
          builtins.head wallpapers
        else
          {
            wallpaperURL = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-dracula.png";
            wallpaperSHA256 = "011cbqn0jzifrbjbkmngnlq77lwpxxdrkby0r36h7j5w1yxxn4ik";
          };
    in
    {
      stylix = {
        enable = true;
        polarity = myconfig.constants.theme.polarity or "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme or "catppuccin-mocha"
        }.yaml";
        image = pkgs.fetchurl {
          url = wallpaper.wallpaperURL;
          sha256 = wallpaper.wallpaperSHA256;
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

  # 🌟 3. HOME MANAGER CONFIG: Application Targets & Catppuccin GTK overrides
  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
    in
    {
      # THE FIX: Targets are now safely in the Home Manager block!
      stylix.targets = {
        neovim.enable = false;
        wofi.enable = false;
        waybar.enable = false;
        #hyprpaper.enable = false;
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
      // cfg.targets; # <--- This cleanly applies your host exclusions from default.nix!

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
