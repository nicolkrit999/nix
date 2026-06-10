{ delib, pkgs, lib, ... }:
delib.module {
  name = "programs.waypaper";
  options = delib.singleEnableOption false;

  home.ifEnabled = { ... }: {
    home.packages = with pkgs; [
      waypaper
      swaybg
      mpvpaper
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      linux-wallpaperengine
    ];
    # No config.ini management — waypaper owns its mutable GUI state.
    # Enabling this module disables all declarative WM wallpaper commands;
    # WMs will run 'waypaper --restore' at startup instead.
  };
}
