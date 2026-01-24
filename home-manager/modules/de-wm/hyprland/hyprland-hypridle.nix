{
  pkgs,
  lib,
  config,
  vars,
  inputs,
  ...
}:
let
  noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # It intercepts the 'lock' command and routes it correctly.
  # Needed to make the lock work in noctalia
  universalLock = pkgs.writeShellScriptBin "universal-lock" ''
    # This detects '.noctalia-shell-wrapped' which Nix creates.
    if pgrep -f "noctalia-shell" > /dev/null; then
       ${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock
       exit 0
    fi

    # 2. If Caelestia or default Hyprland is running, use Hyprlock
    if command -v hyprlock > /dev/null; then
       pidof hyprlock || hyprlock
       exit 0
    fi

    echo "No locker found! (Check if Noctalia is running or Hyprlock is installed)"
  '';
in
{
  config = lib.mkIf (vars.idleConfig.enable or false) {

    home.packages = [ universalLock ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "${universalLock}/bin/universal-lock";

          unlock_cmd = "";

          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          {
            timeout = vars.idleConfig.dimTimeout;
            on-timeout = "brightnessctl -s set 10";
            on-resume = "brightnessctl -r";
          }
          {
            timeout = vars.idleConfig.lockTimeout;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = vars.idleConfig.screenOffTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = vars.idleConfig.suspendTimeout;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
