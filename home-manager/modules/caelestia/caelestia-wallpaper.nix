{
  pkgs,
  lib,
  vars,
  inputs,
  ...
}:
let
  enabledMonitors = builtins.filter (m: builtins.match ".*disable.*" m == null) (
    vars.monitors or [ ]
  );

  monitorNames = map (m: builtins.head (lib.splitString "," m)) enabledMonitors;

  wallpaperPaths = map (
    w:
    pkgs.fetchurl {
      url = w.wallpaperURL;
      sha256 = w.wallpaperSHA256;
    }
  ) (vars.wallpapers or [ ]);

  fallbackWallpaper = if wallpaperPaths == [ ] then null else builtins.head wallpaperPaths;

  pickWallpaper =
    i:
    if i < builtins.length wallpaperPaths then builtins.elemAt wallpaperPaths i else fallbackWallpaper;

  usedWallpapers = lib.unique (lib.imap0 (i: _: pickWallpaper i) monitorNames);

  hyprpaperConf = lib.concatStringsSep "\n" (
    # Preload lines
    (map (p: "preload = ${toString p}") (builtins.filter (p: p != null) usedWallpapers))
    ++ (lib.imap0 (
      i: mon:
      let
        wp = pickWallpaper i;
      in
      if wp == null then "" else "wallpaper = ${mon},${toString wp}"
    ) monitorNames)
  );
in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf ((vars.hyprland or false) && (vars.caelestia or false)) {
    home.packages = [ pkgs.hyprpaper ];

    xdg.configFile."hypr/hyprpaper.conf".text = hyprpaperConf;

    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "sh -lc 'pkill hyprpaper || true; hyprpaper -c $HOME/.config/hypr/hyprpaper.conf'"
    ];

    programs.caelestia.settings.background.enabled = lib.mkForce false;
  };
}
