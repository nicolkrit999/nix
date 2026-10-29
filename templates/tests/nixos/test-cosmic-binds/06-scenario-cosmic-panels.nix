let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  mk = lib.mkForce;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  twin = extra: fx.mkNixos [{ myconfig.programs.cosmic.enable = mk true; } extra];
  plain = twin { };
  pinned = twin { myconfig.programs.cosmic.pinnedApps = mk [ "zen-beta.desktop" "org.kde.dolphin.desktop" "plainid" "zen-beta.desktop" ]; };
  hidden = twin { myconfig.programs.cosmic.panelAutohide = mk "Always"; myconfig.programs.cosmic.dockAutohide = mk "Never"; };
  swapped = twin { myconfig.programs.cosmic.panelAutohide = mk "OnOverlap"; myconfig.programs.cosmic.dockAutohide = mk "Always"; };
  off = fx.mkNixos [{ myconfig.programs.cosmic.enable = mk false; myconfig.programs.cosmic.pinnedApps = mk [ "a.desktop" ]; }];

  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;

  cosmicOf = t: (fx.hmOf t).wayland.desktopManager.cosmic;
  panelsOf = t: (cosmicOf t).panels;
  byName = t: n: lib.findFirst (x: x.name == n) null (panelsOf t);
  hasFile = t: k: (cosmicOf t).configFile ? ${k};
  autohideOf = t: n: (cosmicOf t).configFile."com.system76.CosmicPanel.${n}".entries.autohide;
  favoritesOf = t: (cosmicOf t).applets.app-list.settings.favorites;

  en = v: { __type = "enum"; variant = v; };
  opt = v: { __type = "optional"; value = v; };
  wings = l: r: opt { __type = "tuple"; value = [ l r ]; };
  a = id: "com.system76.${id}";

  expected = {
    Panel = {
      anchor = en "Top";
      size = en "XS";
      output = en "All";
      background = en "ThemeDefault";
      expand_to_edges = true;
      anchor_gap = false;
      exclusive_zone = true;
      margin = 0;
      padding = 0;
      spacing = 2;
      border_radius = 0;
      opacity = 1.0;
      plugins_center = opt [ (a "CosmicAppletTime") ];
      plugins_wings = wings
        [ (a "CosmicPanelWorkspacesButton") (a "CosmicPanelAppButton") ]
        (map a [ "CosmicAppletInputSources" "CosmicAppletStatusArea" "CosmicAppletA11y" "CosmicAppletTiling" "CosmicAppletAudio" "CosmicAppletBluetooth" "CosmicAppletNetwork" "CosmicAppletBattery" "CosmicAppletNotifications" "CosmicAppletPower" ]);
    };
    Dock = {
      anchor = en "Bottom";
      size = en "L";
      output = en "All";
      background = en "ThemeDefault";
      expand_to_edges = false;
      anchor_gap = false;
      exclusive_zone = false;
      margin = 0;
      padding = 4;
      spacing = 4;
      border_radius = 12;
      opacity = 1.0;
      plugins_center = opt (map a [ "CosmicPanelLauncherButton" "CosmicPanelWorkspacesButton" "CosmicPanelAppButton" "CosmicAppList" "CosmicAppletMinimize" ]);
      plugins_wings = wings [ ] [ ];
    };
  };

  # Every key of the live COSMIC 1.11 files except `autohide` (enum, written separately through configFile)
  writtenKeys = [
    "anchor"
    "anchor_gap"
    "autohide_behavior"
    "autohover_delay_ms"
    "background"
    "border_radius"
    "border_width"
    "exclusive_zone"
    "expand_to_edges"
    "keep_style_on_maximize"
    "keyboard_interactivity"
    "layer"
    "margin"
    "name"
    "opacity"
    "output"
    "padding"
    "padding_overlap"
    "plugins_center"
    "plugins_wings"
    "size"
    "size_center"
    "size_wings"
    "spacing"
  ];

  nonNullKeys = p: lib.sort (x: y: x < y) (lib.attrNames (lib.filterAttrs (_: v: v != null) p));

  panelProblems = name: p:
    lib.optional (p == null) "${name} missing"
    ++ lib.optionals (p != null) (
      lib.concatMap
        (k: lib.optional ((p.${k} or null) != expected.${name}.${k}) "${name}.${k} is ${builtins.toJSON (p.${k} or null)}")
        (lib.attrNames expected.${name})
    );

  stripDesktop = map (lib.removeSuffix ".desktop");
in
{
  results = {
    "panels: exactly Panel then Dock, nothing else" =
      let ns = map (x: x.name) (panelsOf plain); in
      if ns == [ "Panel" "Dock" ] then ok else "FAIL: panels are ${builtins.toJSON ns}";
    "panels: Panel equals the reproduced COSMIC default (anchor, size, output, spacing, plugins)" =
      failIf (panelProblems "Panel" (byName plain "Panel"));
    "panels: Dock equals the reproduced COSMIC default (anchor, size, output, spacing, plugins)" =
      failIf (panelProblems "Dock" (byName plain "Dock"));
    "panels: output is All on both, never the module default Name Virtual-1" =
      failIf (lib.concatMap (n: lib.optional ((byName plain n).output != en "All") "${n} output ${builtins.toJSON (byName plain n).output}") [ "Panel" "Dock" ]);
    "panels: plugin lists equal the default lists (center and wings)" =
      failIf (lib.concatMap
        (n: lib.optional ((byName plain n).plugins_center != expected.${n}.plugins_center) "${n} center"
          ++ lib.optional ((byName plain n).plugins_wings != expected.${n}.plugins_wings) "${n} wings")
        [ "Panel" "Dock" ]);
    "panels: the Dock has no wing applets, its center carries the app list" =
      let d = byName plain "Dock"; in
      failIf (
        lib.optional (d.plugins_wings != wings [ ] [ ]) "wings not empty"
        ++ lib.optional (!(lib.elem (a "CosmicAppList") d.plugins_center.value)) "no app list in center"
      );
    "panels: each panel restates the complete live key set (24 keys, autohide excluded)" =
      failIf (lib.concatMap
        (n: lib.optional (nonNullKeys (byName plain n) != lib.sort (x: y: x < y) writtenKeys) "${n} keys ${builtins.toJSON (nonNullKeys (byName plain n))}")
        [ "Panel" "Dock" ]);
    "panels: the panels option leaves autohide unset (the enum goes through configFile)" =
      failIf (lib.concatMap (n: lib.optional ((byName plain n).autohide != null) "${n} autohide set") [ "Panel" "Dock" ]);
    "autohide: defaults equal the live enums (Panel Never, Dock OnOverlap) in the component files" =
      failIf (lib.concatMap
        (x: lib.optional (autohideOf plain x.n != en x.v) "${x.n} autohide is ${builtins.toJSON (autohideOf plain x.n)}")
        [{ n = "Panel"; v = "Never"; } { n = "Dock"; v = "OnOverlap"; }]);
    "autohide: changed options propagate, each only to its own component" =
      failIf (
        lib.optional (autohideOf hidden "Panel" != en "Always") "panelAutohide not propagated"
        ++ lib.optional (autohideOf hidden "Dock" != en "Never") "dockAutohide not propagated"
        ++ lib.optional (autohideOf swapped "Panel" != en "OnOverlap" || autohideOf swapped "Dock" != en "Always") "options leak into the wrong component"
      );
    "autohide: merges with the panels module's own entries (same files, version 1, all keys kept)" =
      failIf (lib.concatMap
        (n:
          let f = (cosmicOf plain).configFile."com.system76.CosmicPanel.${n}"; in
          lib.optional (f.version != 1) "${n} version ${toString f.version}"
          ++ lib.optional (f.entries.name != n) "${n} panel entries lost"
          ++ lib.optional (f.entries.autohide_behavior != { wait_time = 1000; transition_time = 200; handle_size = 4; unhide_delay = 200; }) "${n} autohide_behavior lost"
          ++ lib.optional (!(f.entries ? autohide)) "${n} autohide missing")
        [ "Panel" "Dock" ]);
    "autohide: options accept only Never, OnOverlap and Always" =
      let
        tryVal = v: (builtins.tryEval (builtins.deepSeq (twin { myconfig.programs.cosmic.dockAutohide = mk v; }).config.myconfig.programs.cosmic.dockAutohide true)).success;
      in
      failIf (lib.optional (!tryVal "Always") "Always rejected" ++ lib.optional (tryVal "Sometimes") "bogus variant accepted");
    "autohide: cosmic off writes no panel component files at all" =
      failIf (lib.concatMap (n: lib.optional (hasFile off "com.system76.CosmicPanel.${n}") "${n} file with cosmic off") [ "Panel" "Dock" ]);
    "autohide: control, a wrong variant is detected" =
      detects "wrong autohide" (lib.optional (autohideOf plain "Dock" != en "Always") "Dock");
    "panels: autohide_behavior carries the live numbers" =
      failIf (lib.concatMap
        (n: lib.optional ((byName plain n).autohide_behavior != { wait_time = 1000; transition_time = 200; handle_size = 4; unhide_delay = 200; }) "${n} behavior")
        [ "Panel" "Dock" ]);
    "panels: remaining live scalars (border_width, padding_overlap, hover delay, layer, keyboard)" =
      failIf (lib.concatMap
        (n:
          let p = byName plain n; in
          lib.optional (p.border_width != 0.0 || p.padding_overlap != 0.5) "${n} floats"
          ++ lib.optional (p.autohover_delay_ms != opt 500) "${n} hover delay"
          ++ lib.optional (p.layer != en "Top" || p.keyboard_interactivity != en "OnDemand") "${n} layer/keyboard"
          ++ lib.optional (p.keep_style_on_maximize != false) "${n} keep_style"
          ++ lib.optional (p.size_center != opt null || p.size_wings != opt null) "${n} size_center/wings")
        [ "Panel" "Dock" ]);
    "panels: CosmicPanel entries list is Panel, Dock; one config file per panel (version 1)" =
      let
        c = (cosmicOf plain).configFile;
        e = c."com.system76.CosmicPanel";
      in
      failIf (
        lib.optional (e.entries.entries != [ "Panel" "Dock" ]) "entries ${builtins.toJSON e.entries.entries}"
        ++ lib.optional (!(c ? "com.system76.CosmicPanel.Panel") || !(c ? "com.system76.CosmicPanel.Dock")) "panel files"
        ++ lib.optional (c."com.system76.CosmicPanel.Dock".version != 1) "version"
        ++ lib.optional (c."com.system76.CosmicPanel.Dock".entries.name != "Dock") "Dock file content"
      );
    "panels: panel restart activation exists when panels are declared" =
      if (fx.hmOf plain).home.activation ? restartCosmicPanel then ok else "FAIL: no restartCosmicPanel activation";
    "pinned: favorites are the pinnedApps with .desktop stripped, order kept, duplicates dropped" =
      if favoritesOf pinned == [ "zen-beta" "org.kde.dolphin" "plainid" ] then ok else "FAIL: favorites ${builtins.toJSON (favoritesOf pinned)}";
    "pinned: favorites reach the CosmicAppList config file (version 1)" =
      let f = (cosmicOf pinned).configFile."com.system76.CosmicAppList" or null; in
      if f != null && f.version == 1 && f.entries.favorites == [ "zen-beta" "org.kde.dolphin" "plainid" ] then ok else "FAIL: ${builtins.toJSON f}";
    "pinned: empty pinnedApps writes no favorites and no app list file, panels still set" =
      failIf (
        lib.optional (favoritesOf plain != null) "favorites set for an empty list"
        ++ lib.optional (hasFile plain "com.system76.CosmicAppList") "CosmicAppList written"
        ++ lib.optional (map (x: x.name) (panelsOf plain) != [ "Panel" "Dock" ]) "panels missing"
      );
    "pinned: pinnedApps defaults to an empty list" =
      if plain.config.myconfig.programs.cosmic.pinnedApps == [ ] then ok else "FAIL: default not empty";
    "pinned: real desktop favorites derive from its pinnedApps (same list as gnome and kde)" =
      let
        c = desktop.config.myconfig.programs;
        f = favoritesOf { config = desktop.config; };
      in
      failIf (
        lib.optional (c.cosmic.pinnedApps == [ ]) "desktop cosmic pinnedApps empty"
        ++ lib.optional (c.cosmic.pinnedApps != c.gnome.pinnedApps || c.cosmic.pinnedApps != c.kde.pinnedApps) "cosmic list differs from gnome/kde"
        ++ lib.optional (f != stripDesktop c.cosmic.pinnedApps) "favorites ${builtins.toJSON f}"
        ++ lib.optional (lib.any (lib.hasInfix ".desktop") f) "a favorite still has .desktop"
      );
    "pinned: real laptop declares the same pinnedApps (cosmic off there)" =
      let c = laptop.config.myconfig.programs; in
      if c.cosmic.pinnedApps != [ ] && c.cosmic.pinnedApps == c.gnome.pinnedApps then ok else "FAIL: laptop cosmic pinnedApps ${builtins.toJSON c.cosmic.pinnedApps}";
    "panels: real desktop emits Panel and Dock" =
      let ns = map (x: x.name) (panelsOf { config = desktop.config; }); in
      if ns == [ "Panel" "Dock" ] then ok else "FAIL: ${builtins.toJSON ns}";
    "panels: cosmic off emits no panels, no panel files, no app list, no restart" =
      failIf (
        lib.optional ((cosmicOf off).panels != null) "panels set with cosmic off"
        ++ lib.optional (hasFile off "com.system76.CosmicPanel") "CosmicPanel file with cosmic off"
        ++ lib.optional (hasFile off "com.system76.CosmicAppList") "CosmicAppList with cosmic off"
        ++ lib.optional ((cosmicOf off).applets.app-list.settings.favorites != null) "favorites with cosmic off"
        ++ lib.optional ((fx.hmOf off).home.activation ? restartCosmicPanel) "restart activation with cosmic off"
      );
    "panels: control, the module default output (Name Virtual-1) is detected" =
      detects "Virtual-1" (panelProblems "Panel" ((byName plain "Panel") // { output = { __type = "enum"; variant = "Name"; value = [ "Virtual-1" ]; }; }));
    "panels: control, a wrong anchor is detected" =
      detects "anchor" (panelProblems "Dock" ((byName plain "Dock") // { anchor = en "Top"; }));
    "panels: control, a dropped applet is detected" =
      detects "missing applet" (panelProblems "Panel" ((byName plain "Panel") // { plugins_center = opt [ ]; }));
    "panels: control, a missing panel is detected" =
      detects "missing Dock" (panelProblems "Dock" null);
  };
}
