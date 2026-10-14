{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  hypr = H.getConfig ./04-hyprland-no-shell;
  multi = H.getConfig ./06-multi-wm-shell-on-niri;
  nowm = H.getConfig ./07-no-wm;
  svc = c: (H.getHm c).systemd.user.services.hypridle;
  listeners = c: (H.getHm c).services.hypridle.settings.listener;
  general = c: (H.getHm c).services.hypridle.settings.general;
  onTimeouts = c: map (l: l.on-timeout) (listeners c);
  any' = pred: xs: builtins.any pred xs;
  dim = c: (builtins.head (listeners c)).on-timeout;
  resumeOf = c: (builtins.head (listeners c)).on-resume;
  contract = c: {
    "no graphical-session.target in WantedBy" = !(builtins.elem "graphical-session.target" (svc c).Install.WantedBy);
    "three listeners" = builtins.length (listeners c) == 3;
    "no on-timeout has an inline pgrep -f" = !(any' (lib.hasInfix "pgrep -f") (onTimeouts c));
    "every on-timeout runs the nix-busy script" = builtins.all (lib.hasInfix "nix-busy") (onTimeouts c);
    "control: the dpms on-timeout still has pgrep (-x), so the pgrep -f scan can see pgrep" = any' (lib.hasInfix "pgrep -x") (onTimeouts c);
    "dim uses brightnessctl -c backlight, set and restore" = lib.hasInfix "brightnessctl -c backlight -s set" (dim c) && lib.hasInfix "brightnessctl -c backlight -r" (resumeOf c);
    "no unlock_cmd" = !(general c ? unlock_cmd);
    "lock_cmd is still set (control for the unlock_cmd absence)" = general c ? lock_cmd;
  };
  eachTrue = helpers: attrs: lib.mapAttrs (_: helpers.isTrue) attrs;
in
nix-tests.runTests {
  "C10: hypridle on hyprland only" = helpers: eachTrue helpers (contract hypr // {
    "WantedBy is exactly the hyprland session target" = (svc hypr).Install.WantedBy == [ "hyprland-session.target" ];
    "PartOf and After match WantedBy" = (svc hypr).Unit.PartOf == (svc hypr).Install.WantedBy && (svc hypr).Unit.After == (svc hypr).Install.WantedBy;
    "pam service hyprlock exists" = hypr.security.pam.services ? hyprlock;
  });
  "C11: hypridle on hyprland+niri+mango" = helpers: eachTrue helpers (contract multi // {
    "WantedBy is exactly the three WM session targets" = (svc multi).Install.WantedBy == [ "hyprland-session.target" "niri.service" "mango-session.target" ];
    "pam service hyprlock exists" = multi.security.pam.services ? hyprlock;
  });
  "C12: control, no WM" = helpers: {
    "pam service hyprlock absent" = helpers.isFalse (nowm.security.pam.services ? hyprlock);
    "hypridle disabled" = helpers.isFalse (H.getHm nowm).services.hypridle.enable;
  };
}
