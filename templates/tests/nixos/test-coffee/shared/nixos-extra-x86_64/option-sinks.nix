{ lib, ... }:
let
  sink = lib.mkOption { type = lib.types.bool; default = false; };
  sinks = names: lib.genAttrs names (_: { enable = sink; });
in
{
  options = {
    myconfig = {
      programs = sinks [ "gnome" "kde" "cosmic" "caelestia" "noctalia" "nix-ld" "nix-alien" "claude-code" "claude-desktop" "google-antigravity" "codex" "herdr" "headroom" ];
      services = sinks [ "hyprlock" "swaync" "tailscale" "localsend" ];
      krit.services.nas = sinks [ "smb" "opencloud-mount" "sshfs" "desktop-borg-backup" "laptop-borg-backup" ];
      bluetooth.enable = sink;
      stylix.enable = sink;
    };
    stylix = {
      enable = sink;
      base16Scheme = lib.mkOption { type = lib.types.raw; default = null; };
      image = lib.mkOption { type = lib.types.raw; default = null; };
    };
  };
}
