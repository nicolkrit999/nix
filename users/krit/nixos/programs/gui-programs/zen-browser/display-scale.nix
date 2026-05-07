{ delib, config, lib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }:
    let
      hostname = config.myconfig.constants.hostname;
      scaleMap = {
        "nixos-desktop" = "1.5";
        "nixos-laptop" = "1.6";
      };
    in
    {
      programs.zen-browser.profiles.default.settings =
        lib.optionalAttrs (builtins.hasAttr hostname scaleMap) {
          # Match compositor fractional scale exactly to avoid Firefox rounding up
          # to the nearest integer (e.g. 1.5x → 2x), which blurs extension popups.
          # Not set for unknown hosts → Firefox auto-detects.
          "layout.css.devPixelsPerPx" = scaleMap.${hostname};
        };
    };
}
