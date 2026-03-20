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

  home.always =
    { ... }:
    {
      imports = [
        inputs.catppuccin.homeModules.catppuccin
      ];
    };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
    in
    {
      stylix.targets = {
        neovim.enable = false;
        bat.enable = !isCatppuccin;
        lazygit.enable = !isCatppuccin;
        starship.enable = !isCatppuccin;
      } // cfg.targets;
    };
}
