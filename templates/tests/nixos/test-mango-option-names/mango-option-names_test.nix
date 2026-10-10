{ nix-tests }:
let
  H = import ../test-nixos-wallpapers/shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./01-mango-option-names H.nixosExtraX86;
  settings = (H.getHm config).wayland.windowManager.mango.settings;

  toMango = import (H.flake.inputs.mango.outPath + "/nix/lib.nix") lib;
  rendered = toMango.toMango { } settings;
  renderedKeys = lib.unique (lib.concatMap
    (line:
      let m = builtins.match "([a-z_0-9]+) *= .*" line;
      in if m == null then [ ] else m)
    (lib.splitString "\n" rendered));

  oldKeys = [
    "animation_curve_opafadein"
    "animation_curve_opafadeout"
    "bordercolor"
    "borderpx"
    "default_mfact"
    "default_nmaster"
    "fadein_begin_opacity"
    "fadeout_begin_opacity"
    "focuscolor"
    "gappih"
    "gappiv"
    "gappoh"
    "gappov"
    "globalcolor"
    "idleinhibit_ignore_visible"
    "layerrule"
    "maximizescreencolor"
    "monitorrule"
    "numlockon"
    "overlaycolor"
    "overviewgappi"
    "overviewgappo"
    "rootcolor"
    "scratchpadcolor"
    "shadowscolor"
    "sloppyfocus"
    "smartgaps"
    "tagrule"
    "urgentcolor"
    "warpcursor"
    "windowrule"
  ];

  oldRuleFields = [
    "appid"
    "isfloating"
    "offsetx"
    "offsety"
    "nofocus"
    "nofadein"
    "nofadeout"
    "isnoborder"
    "isnoshadow"
    "isnoradius"
    "isnoanimation"
    "isopensilent"
    "istagsilent"
    "isnamedscratchpad"
    "isunglobal"
    "isglobal"
    "isoverlay"
    "isnosizehint"
    "idleinhibit_when_focus"
    "isterm"
    "force_fakemaximize"
    "noswallow"
    "noblur"
    "isfullscreen"
    "isfakefullscreen"
    "globalkeybinding"
  ];
  oldTagFields = [ "nmaster" "mfact" ];
  oldLayerFields = [ "noblur" "noanim" "noshadow" ];
  oldFieldRe = fields: ".*(^|,)(${lib.concatStringsSep "|" fields}):.*";
  hasOld = fields: rule: builtins.match (oldFieldRe fields) rule != null;
  hasOldField = hasOld oldRuleFields;

  windowRules = settings.window_rule or [ ];
  windowRulesOnce = settings.window_rule_once or [ ];
  tagRules = settings.tag_rule or [ ];
  layerRules = settings.layer_rule or [ ];
  bindList = settings.bind or [ ];
  bindlList = settings.bindl or [ ];
  bindslList = settings.bindsl or [ ];
  isPausePlay = b: lib.hasInfix "XF86AudioPause" b || lib.hasInfix "XF86AudioPlay" b;
  leftoverKeys = builtins.filter (k: builtins.elem k oldKeys) (builtins.attrNames settings);
  leftoverRendered = builtins.filter (k: builtins.elem k oldKeys) renderedKeys;
in
nix-tests.runTests {
  "M01: mango settings use only 0.18.0 keyword names" = helpers: {
    "settings attrset has none of the pre-0.18.0 keys" =
      helpers.isTrue (leftoverKeys == [ ]);
    "rendered config.conf text has none of the pre-0.18.0 keys" =
      helpers.isTrue (leftoverRendered == [ ]);
    "rendered config.conf text is non-empty and parsed into keys" =
      helpers.isTrue (builtins.length renderedKeys > 10);
    "window_rule entries use none of the pre-0.18.0 sub-field names" =
      helpers.isTrue (windowRules != [ ] && !(builtins.any hasOldField windowRules));
    "window_rule entries use app_id and is_floating" =
      helpers.isTrue (builtins.any (r: lib.hasInfix "app_id:" r) windowRules
        && builtins.any (r: lib.hasInfix "is_floating:" r) windowRules);
    "monitor rules render under monitor_rule" =
      helpers.isTrue (builtins.length (settings.monitor_rule or [ ]) == 2
        && builtins.elem "monitor_rule" renderedKeys);
    "monitor_rule carries the disable:1 field on HDMI-A-1" =
      helpers.isTrue (builtins.any (r: lib.hasInfix "HDMI-A-1" r && lib.hasInfix "disable:1" r) settings.monitor_rule);
    "tag_rule and layer_rule render under their snake_case keys" =
      helpers.isTrue (builtins.elem "tag_rule" renderedKeys && builtins.elem "layer_rule" renderedKeys);
    "window_rule_once is set, rendered, and uses none of the old sub-field names" =
      helpers.isTrue (windowRulesOnce != [ ]
        && builtins.elem "window_rule_once" renderedKeys
        && !(builtins.any hasOldField windowRulesOnce));
    "window_rule_once entries use app_id" =
      helpers.isTrue (builtins.all (r: lib.hasInfix "app_id:" r) windowRulesOnce);
    "window_rule entries use none of the old sub-field names (full 0.18.0 rename list)" =
      helpers.isTrue (!(builtins.any hasOldField windowRules));
    "the old-sub-field detector flags a legacy rule (self-check)" =
      helpers.isTrue (hasOldField "isfloating:1,appid:^x$" && hasOldField "monitor:DP-1,noblur:1");
    "tag_rule entries use master_count/master_factor, not nmaster/mfact" =
      helpers.isTrue (tagRules != [ ] && !(builtins.any (hasOld oldTagFields) tagRules));
    "layer_rule entries use no_blur/no_animation/no_shadow, not noblur/noanim/noshadow" =
      helpers.isTrue (layerRules != [ ] && !(builtins.any (hasOld oldLayerFields) layerRules));
    "bind, bindl and bindsl render as separate keys" =
      helpers.isTrue (builtins.all (k: builtins.elem k renderedKeys) [ "bind" "bindl" "bindsl" ]);
    "Pause/Play media keys are in bindsl (key-symbol match)" =
      helpers.isTrue (builtins.length (builtins.filter isPausePlay bindslList) == 2);
    "Pause/Play media keys are NOT in bindl" =
      helpers.isFalse (builtins.any isPausePlay bindlList);
    "volume and brightness keys render under bindl (work on a locked screen)" =
      helpers.isTrue (builtins.any (b: lib.hasInfix "XF86AudioRaiseVolume" b) bindlList
        && builtins.any (b: lib.hasInfix "XF86MonBrightnessUp" b) bindlList);
    "the retired plain 'binds' key is no longer rendered" =
      helpers.isFalse (builtins.elem "binds" renderedKeys);
    "SUPER+CTRL+arrows resize instead of focusing a monitor" =
      helpers.isTrue (builtins.elem "SUPER+CTRL,Left,resizewin,-60,+0" bindList
        && !(builtins.any (b: lib.hasPrefix "SUPER+CTRL,Left," b && lib.hasInfix "focusmon" b) bindList));
    "SUPER+SHIFT+1 moves silently (tagsilent), SUPER+ALT+1 moves and follows (tag)" =
      helpers.isTrue (builtins.elem "SUPER+SHIFT,1,tagsilent,1" bindList
        && builtins.elem "SUPER+ALT,1,tag,1,0" bindList);
    "SUPER+S toggles the special tag" =
      helpers.isTrue (builtins.elem "SUPER,S,toggle_special_tag" bindList);
    "no middle-click mousebind" =
      helpers.isFalse (builtins.any (b: lib.hasInfix "btn_middle" b) (settings.mousebind or [ ]));
  };
}
