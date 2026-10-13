# P08 — Hyprland, mango and niri, no shell, vicinae explicitly disabled
# Expected: no launcher at all on hyprland, the no-op on mango and niri; the vicinae binds are gone on all three.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  lib = H.lib;
  hyprConfig = H.getConfig ./08-hyprland-no-shell-no-vicinae;
  hypr = H.getHm hyprConfig;
  mangoConfig = H.getConfig ./09-mango-no-shell-no-vicinae;
  mango = H.getHm mangoConfig;
  niriConfig = H.getConfig ./10-niri-no-shell-no-vicinae;
  niriBinds = (H.getHm niriConfig).programs.niri.settings.binds;
  niriOnBinds = (H.getHm (H.getConfig ./05-niri-no-shell)).programs.niri.settings.binds;
  hyprKeys = map (b: builtins.elemAt b._args 0)
    (builtins.filter (b: !(builtins.isString b)) hypr.wayland.windowManager.hyprland.settings.bind);
in
nix-tests.runTests {
  "P08: no shell and vicinae disabled" = helpers: {
    "hyprland: no failing assertions" =
      helpers.isTrue (H.allAssertionsPass hyprConfig);
    "hyprland: Super+Shift+A is not bound at all" =
      helpers.isTrue (!(lib.elem "SUPER+SHIFT + A" hyprKeys));
    "hyprland: Super+A (vicinae) is not bound" =
      helpers.isTrue (!(lib.elem "SUPER + A" hyprKeys));
    "hyprland: control, Super+Delete is still bound" =
      helpers.isTrue (lib.hasInfix "loginctl lock-session" (H.hyprBind hypr "SUPER + Delete"));
    "mango: no failing assertions" =
      helpers.isTrue (H.allAssertionsPass mangoConfig);
    "mango: SUPER+SHIFT,A is bound exactly once, to the no-op" =
      helpers.isEq (H.mangoBinds mango "SUPER+SHIFT,A,spawn,") [ "SUPER+SHIFT,A,spawn,true" ];
    "mango: SUPER,A (vicinae) is not bound" =
      helpers.isEq (H.mangoBinds mango "SUPER,A,spawn,") [ ];
    "mango: control, SUPER,Delete is still bound" =
      helpers.isEq (H.mangoBinds mango "SUPER,Delete,spawn,") [ "SUPER,Delete,spawn,loginctl lock-session" ];
    "niri: no failing assertions" =
      helpers.isTrue (H.allAssertionsPass niriConfig);
    "niri: Mod+Shift+A is the no-op" =
      helpers.isEq niriBinds."Mod+Shift+A".action.spawn [ "true" ];
    "niri: Mod+A, Mod+Period and Mod+V (vicinae) are not bound" =
      helpers.isEq (lib.filter (k: niriBinds ? ${k}) [ "Mod+A" "Mod+Period" "Mod+V" ]) [ ];
    "niri: control, Mod+Delete is still bound" =
      helpers.isEq niriBinds."Mod+Delete".action.spawn [ "loginctl" "lock-session" ];
    "niri: control, with vicinae on the same three binds exist" =
      helpers.isEq (lib.filter (k: niriOnBinds ? ${k}) [ "Mod+A" "Mod+Period" "Mod+V" ]) [ "Mod+A" "Mod+Period" "Mod+V" ];
    "niri: control, with vicinae on Mod+Shift+A is vicinae toggle" =
      helpers.isEq niriOnBinds."Mod+Shift+A".action.spawn [ "vicinae" "toggle" ];
  };
}
