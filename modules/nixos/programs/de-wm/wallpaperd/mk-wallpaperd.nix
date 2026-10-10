{ lib, pkgs }:
{ wm, wallpapers }:
let
  kindOf = w: if w.videoURL != "" || w.gifURL != "" then "video" else "image";
  mediaOf = w:
    if w.videoURL != "" then
      pkgs.fetchurl { url = w.videoURL; sha256 = w.videoSHA256; }
    else if w.gifURL != "" then
      pkgs.fetchurl { url = w.gifURL; sha256 = w.gifSHA256; }
    else
      pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };

  targets = map (w: w.targetMonitor) wallpapers;
  specs = map (w: "${w.targetMonitor}=${kindOf w}:${mediaOf w}") wallpapers;
  needsAwww = lib.any (w: kindOf w == "image") wallpapers;
  needsMpv = lib.any (w: kindOf w == "video") wallpapers;

  checked =
    assert lib.assertMsg
      (lib.all (t: !(lib.hasInfix "$(" t || lib.hasInfix "`" t)) targets)
      "wallpapers: targetMonitor must be a connector name, desc:<make model serial> or *, not a shell substitution";
    assert lib.assertMsg
      (lib.length (lib.unique targets) == lib.length targets)
      "wallpapers: duplicate targetMonitor";
    true;

  package = pkgs.writeShellApplication {
    name = "${wm}-wallpaperd";
    runtimeInputs = [ pkgs.jq pkgs.util-linux pkgs.coreutils pkgs.gnugrep ]
      ++ lib.optional (wm == "mango") pkgs.wlr-randr
      ++ lib.optional (wm == "hyprland") pkgs.socat
      ++ lib.optional needsAwww pkgs.awww
      ++ lib.optional needsMpv pkgs.mpvpaper;
    text = builtins.readFile ./wallpaperd.sh;
  };

  argv = [ (lib.getExe package) "--wm" wm ] ++ specs;

  launcher = pkgs.writeShellScript "${wm}-wallpaperd-start" ''
    # hwdec=vaapi: skip mpv's nvdec probe, which prints "Cannot load libcuda.so.1"
    # on AMD/Intel and then falls through to vaapi anyway.
    export WALLPAPERD_MPV_EXTRA="msg-level=all=warn hwdec=vaapi"
    exec ${lib.escapeShellArgs argv} >>"''${XDG_RUNTIME_DIR:-/tmp}/${wm}-wallpaperd.log" 2>&1
  '';
in
assert checked;
{
  inherit package needsAwww needsMpv specs argv launcher;

  startupCmds = lib.optionals (wallpapers != [ ]) (
    lib.optional needsAwww "awww-daemon --no-cache"
    ++ [ (lib.escapeShellArgs argv) ]
  );

  launcherCmds = lib.optionals (wallpapers != [ ]) (
    lib.optional needsAwww "awww-daemon --no-cache"
    ++ [ "${launcher}" ]
  );

  startupArgv = lib.optionals (wallpapers != [ ]) (
    lib.optional needsAwww [ "awww-daemon" "--no-cache" ]
    ++ [ argv ]
  );
}
