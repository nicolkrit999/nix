{ lib, ... }:
let
  sink = lib.mkOption { type = lib.types.bool; default = false; };
  sinks = names: lib.genAttrs names (_: { enable = sink; });
in
{
  options = {
    environment.persistence = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.directories = lib.mkOption {
          type = lib.types.listOf (lib.types.coercedTo lib.types.str (directory: { inherit directory; }) (lib.types.submodule {
            options = {
              directory = lib.mkOption { type = lib.types.str; };
              user = lib.mkOption { type = lib.types.str; default = "root"; };
              group = lib.mkOption { type = lib.types.str; default = "root"; };
              mode = lib.mkOption { type = lib.types.str; default = "0755"; };
            };
          }));
          default = [ ];
        };
      });
      default = { };
    };
    sops.secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule { options.mode = lib.mkOption { type = lib.types.str; default = "0400"; }; });
      default = { };
    };
    myconfig = {
      programs = sinks [ "gnome" "kde" "cosmic" "caelestia" "noctalia" "nix-ld" "nix-alien" "claude-code" "claude-desktop" "google-antigravity" "codex" "herdr" "headroom" ];
      services = sinks [ "hyprlock" "swaync" "tailscale" "localsend" ];
      krit.services.nas = sinks [ "smb" "opencloud-mount" "sshfs" "desktop-borg-backup" "laptop-borg-backup" ];
      bluetooth = { enable = sink; autoEnableOnBoot = sink; };
      stylix.enable = sink;
    };
    stylix = {
      enable = sink;
      base16Scheme = lib.mkOption { type = lib.types.raw; default = null; };
      image = lib.mkOption { type = lib.types.raw; default = null; };
    };
  };

  config.environment.persistence."/persist".directories = [ "/var/lib/systemd/linger" ];
}
