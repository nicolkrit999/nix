{ delib
, lib
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "programs.cosmic";

  options =
    with delib;
    moduleOptions {
      extraBinds = attrsOption { };
      # COSMIC defaults duplicating our binds: lock (our Super+Delete), logout (our Super+Shift+Delete),
      # close (our Super+Shift+C), fullscreen (our Super+M), terminal (our Super+Return)
      disabledDefaults = listOfOption lib.types.str [ "Super+Escape" "Super+Shift+Escape" "Super+q" "Super+F11" "Super+t" ];
      monitors = listOfOption
        (submodule {
          options = {
            output = strOption "*";
            width = intOption 0;
            height = intOption 0;
            refresh = numberOption 0;
            scale = numberOption 1.0;
            x = intOption 0;
            y = intOption 0;
            transform = enumOption [ 0 90 180 270 ] 0;
            enable = boolOption true;
          };
        })
        [{ output = "*"; }];
      # Input options: null means "not declared"; a device kind (touchpad, mouse) is only written when at least one of its options is set
      keyboardRepeatDelay = lib.mkOption { type = lib.types.nullOr lib.types.ints.unsigned; default = null; description = "Key repeat delay in ms; null keeps COSMIC's 600."; };
      keyboardRepeatRate = lib.mkOption { type = lib.types.nullOr lib.types.ints.unsigned; default = null; description = "Key repeat rate in repeats per second; null keeps COSMIC's 25."; };
      touchpadTapToClick = lib.mkOption { type = lib.types.nullOr lib.types.bool; default = null; description = "Tap to click on the touchpad."; };
      touchpadNaturalScroll = lib.mkOption { type = lib.types.nullOr lib.types.bool; default = null; description = "Natural scrolling on the touchpad."; };
      touchpadDisableWhileTyping = lib.mkOption { type = lib.types.nullOr lib.types.bool; default = null; description = "Disable the touchpad while typing."; };
      touchpadAccelProfile = lib.mkOption { type = lib.types.nullOr (lib.types.enum [ "Adaptive" "Flat" ]); default = null; description = "Touchpad pointer acceleration profile."; };
      touchpadSpeed = lib.mkOption { type = lib.types.nullOr (lib.types.numbers.between (-1.0) 1.0); default = null; description = "Touchpad pointer speed, -1.0 to 1.0."; };
      mouseNaturalScroll = lib.mkOption { type = lib.types.nullOr lib.types.bool; default = null; description = "Natural scrolling on mice."; };
      mouseAccelProfile = lib.mkOption { type = lib.types.nullOr (lib.types.enum [ "Adaptive" "Flat" ]); default = null; description = "Mouse pointer acceleration profile."; };
      mouseSpeed = lib.mkOption { type = lib.types.nullOr (lib.types.numbers.between (-1.0) 1.0); default = null; description = "Mouse pointer speed, -1.0 to 1.0."; };
      followTheme = boolOption true;
      themeAccent = lib.mkOption { type = lib.types.nullOr (lib.types.enum [ "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F" ]); default = null; description = "Base16 slot used as the COSMIC accent colour; null uses base0D (or the catppuccin accent when catppuccin is on)."; };
      pinnedApps = listOfOption str [ ];
    };

  nixos.always = _: {
    home-manager.sharedModules = [
      inputs.cosmic-manager.homeManagerModules.cosmic-manager
    ];
  };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.cosmic-manager.homeManagerModules.cosmic-manager
    ];
  };

  home.ifEnabled =
    { myconfig, ... }:
    {
      # Enable data control for clipboard tools
      home.sessionVariables = {
        COSMIC_DATA_CONTROL_ENABLED = 1;
        XDG_SCREENSHOTS_DIR = myconfig.constants.screenshots;
      };
    };
}
