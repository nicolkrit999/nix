# Test-only stylix module — mirrors modules/nixos/toplevel/stylix-nixos.nix
# but with a dummy image (no network fetch needed for eval/dry-run).
#
# Gates stylix.enable on myconfig.stylix.enable so specializations that force
# myconfig.stylix.enable = false also suppress stylix.enable at the NixOS level.
{ delib
, lib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "stylix";

  options = with delib; moduleOptions {
    enable = boolOption true;
    targets = attrsOption { };
  };

  nixos.always = { ... }: {
    imports = [ inputs.stylix.nixosModules.stylix ];
    specialisation = lib.genAttrs [ "guest" "safemode" ] (_: {
      configuration.stylix.base16Scheme = lib.mkOverride 40 (import ../../../../lib/scheme-catppuccin-mocha.nix);
    });
  };

  nixos.ifEnabled = _: {
    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = import ../../../../lib/scheme-catppuccin-mocha.nix;
      image = pkgs.runCommand "dummy-wallpaper.png" { } "touch $out";
      cursor = {
        name = "DMZ-Black";
        size = 24;
        package = pkgs.vanilla-dmz;
      };
      fonts = {
        emoji = { name = "Noto Color Emoji"; package = pkgs.noto-fonts-color-emoji; };
        monospace = { name = "JetBrainsMono Nerd Font"; package = pkgs.nerd-fonts.jetbrains-mono; };
        sansSerif = { name = "JetBrainsMono Nerd Font Propo"; package = pkgs.nerd-fonts.jetbrains-mono; };
        serif = { name = "JetBrainsMono Nerd Font Propo"; package = pkgs.nerd-fonts.jetbrains-mono; };
        sizes = { terminal = 13; applications = 11; };
      };
    };
  };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
    in
    {
      stylix.targets = {
        bat.enable = !isCatppuccin;
        lazygit.enable = !isCatppuccin;
        starship.enable = !isCatppuccin;
        qt.enable = false;
        kde.enable = !isCatppuccin;
        hyprland.enable = !isCatppuccin;
        hyprlock.enable = false;
        gtk.enable = !isCatppuccin;
        swaync.enable = !isCatppuccin;
        tmux.enable = !isCatppuccin;
        wofi.enable = false;
        rofi.enable = false;
        waybar.enable = false;
        neovim.enable = false;
        gnome.enable = false;
        gtksourceview.enable = false;
        hyprpaper.enable = lib.mkForce false;
      } // cfg.targets;
    };
}
