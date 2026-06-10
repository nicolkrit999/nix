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
  };
}
