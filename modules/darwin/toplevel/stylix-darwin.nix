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

  darwin.always =
    {
      imports = [
        inputs.stylix.darwinModules.stylix
      ];
    };

  darwin.ifEnabled =
    { myconfig, ... }:
    {
      stylix = {
        enable = true;
        polarity = myconfig.constants.theme.polarity;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${
          myconfig.constants.theme.base16Theme
        }.yaml";

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Propo";
          };
          # JetBrains has no serif face, so serif uses the proportional variant too
          serif = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Propo";
          };
          sizes = {
            terminal = 14;
            desktop = 12;
            popups = 10;
          };
        };
      };
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin;
    in
    {
      stylix.targets = lib.recursiveUpdate
        {
          neovim.enable = false;
          rofi.enable = false;
          bat.enable = !isCatppuccin;
          lazygit.enable = !isCatppuccin;
          starship.enable = !isCatppuccin;
          tmux.enable = !isCatppuccin;
          gtksourceview.enable = false; # Could cause slow-downs during rebuilds. See "https://github.com/nix-community/stylix/discussions/2232#discussion-9598872"
        }
        cfg.targets;
    };
}
