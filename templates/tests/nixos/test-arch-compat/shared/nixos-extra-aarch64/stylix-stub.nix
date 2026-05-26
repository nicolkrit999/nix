# Test-only stylix module — mirrors modules/nixos/toplevel/stylix-nixos.nix
# but with a dummy image (no network fetch needed for --dry-run).
#
# Critical: gates stylix.enable on myconfig.stylix.enable so specializations
# (guest, safe-mode) that set myconfig.stylix.enable = false also have
# stylix.enable = false at the NixOS level. This prevents the HM stylix
# module from being injected via sharedModules, which is required for the
# `options.stylix.enable` re-declaration in guest.nix/safe-mode.nix to work.
{ delib
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
  };

  nixos.ifEnabled = { ... }: {
    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      # Dummy image — no network needed; content irrelevant for aarch64 compat eval.
      image = pkgs.runCommand "dummy-wallpaper.png" { } "touch $out";
      cursor = {
        name = "DMZ-Black";
        size = 24;
        package = pkgs.vanilla-dmz;
      };
      fonts = {
        emoji = { name = "Noto Color Emoji"; package = pkgs.noto-fonts-color-emoji; };
        monospace = { name = "JetBrainsMono Nerd Font"; package = pkgs.nerd-fonts.jetbrains-mono; };
        sansSerif = { name = "Noto Sans"; package = pkgs.noto-fonts; };
        serif = { name = "Noto Serif"; package = pkgs.noto-fonts; };
        sizes = { terminal = 13; applications = 11; };
      };
    };
  };

  home.ifEnabled = { myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
    in
    {
      # Mirror production stylix-nixos.nix target disables for catppuccin mode
      # (catppuccin-nix manages bat/lazygit/starship/kde/hyprland/etc., stylix must not).
      stylix.targets = {
        bat.enable = !isCatppuccin;
        lazygit.enable = !isCatppuccin;
        starship.enable = !isCatppuccin;
        qt.enable = false;
        kde.enable = !isCatppuccin;
        hyprland.enable = !isCatppuccin;
        hyprlock.enable = !isCatppuccin;
        gtk.enable = !isCatppuccin;
        swaync.enable = !isCatppuccin;
        tmux.enable = !isCatppuccin;
        wofi.enable = false;
        waybar.enable = false;
        neovim.enable = false;
        gtksourceview.enable = false;
        hyprpaper.enable = false;
      };
    };
}
