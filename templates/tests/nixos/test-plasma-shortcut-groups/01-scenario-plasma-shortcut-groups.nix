let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostNames = [
    "nixos-desktop"
    "nixos-laptop"
  ];

  variantsOf =
    sys: { base = sys.config; } // lib.mapAttrs (_: s: s.configuration) sys.config.specialisation;
  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
  kdeOn = c: c.myconfig.programs.kde.enable;

  layoutSwitcherComponent = "KDE Keyboard Layout Switcher";
  layoutSwitcherAction = "Switch to Next Keyboard Layout";

  # From the pinned sources (klipper.cpp registers show-on-mouse-pos = Meta+V inside plasmashell;
  # org.kde.plasma.emojier.desktop X-KDE-Shortcuts=Meta+.); not yet confirmed by a live Plasma probe
  defaultOwners = {
    "meta+v" = {
      group = "plasmashell";
      action = "show-on-mouse-pos";
    };
    "meta+." = {
      group = "services/org.kde.plasma.emojier.desktop";
      action = "_launch";
    };
  };

  # Known, accepted clashes: the hotkey shares the key with the default owner below.
  # Reason: verified live 2026-10-18 on the laptop (Plasma 6.7.5): vicinae wins, although kglobalacceld normally lets the first registered owner win.
  # An entry only applies while the default owner matches group and action exactly.
  allowedClashes = [
    {
      key = "meta+v";
      group = "plasmashell";
      action = "show-on-mouse-pos";
    }
    {
      key = "meta+.";
      group = "services/org.kde.plasma.emojier.desktop";
      action = "_launch";
    }
  ];

  legacyDesktopGroups =
    shortcuts:
    lib.filter (g: lib.hasSuffix ".desktop" g && !(lib.hasPrefix "services/" g)) (
      builtins.attrNames shortcuts
    );

  keyList = v: if builtins.isList v then v else [ v ];

  groupProblems =
    shortcuts:
    let
      legacy = legacyDesktopGroups shortcuts;
      doubled = lib.filter (g: shortcuts ? "services/${g}") legacy;
      commaKeys = lib.filter
        (
          g: lib.any (v: lib.any (k: lib.hasInfix "," k) (keyList v)) (lib.attrValues shortcuts.${g})
        )
        legacy;
    in
    lib.unique (doubled ++ commaKeys);

  isReleased =
    v:
    let
      l = if builtins.isList v then v else [ v ];
    in
    l == [ ] || l == [ "none" ];

  collisionsWith =
    owners: allowed: shortcuts: commands:
    let
      keys = lib.unique (map (c: lib.toLower (c.key or "")) (lib.attrValues commands));
      isAllowed =
        k:
        let
          o = owners.${k};
        in
        lib.any (a: a.key == k && a.group == o.group && a.action == o.action) allowed;
      ownerReleased =
        k:
        let
          o = owners.${k};
        in
        shortcuts ? ${o.group}
        && shortcuts.${o.group} ? ${o.action}
        && isReleased shortcuts.${o.group}.${o.action};
    in
    lib.filter (k: owners ? ${k} && !(isAllowed k) && !(ownerReleased k)) keys;

  collisions = collisionsWith defaultOwners allowedClashes;

  switcherMisplaced = shortcuts: (shortcuts.kwin or { }) ? ${layoutSwitcherAction};

  checksOf =
    c:
    let
      hm = hmOf c;
      sc = hm.programs.plasma.shortcuts;
      cmds = hm.programs.plasma.hotkeys.commands;
      bad = groupProblems sc;
      col = collisions sc cmds;
    in
    {
      "legacy .desktop groups migrate cleanly into services/" =
        if bad == [ ] then
          "ok"
        else
          "FAIL: legacy .desktop group(s) also set in services/ form or holding a comma key (kglobalacceld migrateConfig would merge or drop them): ${toString bad}";
      "${layoutSwitcherAction} is not filed under kwin" =
        if switcherMisplaced sc then
          "FAIL: kwin.\"${layoutSwitcherAction}\" is set, the action lives in the \"${layoutSwitcherComponent}\" component"
        else
          "ok";
      "custom hotkeys do not shadow an unreleased Plasma default" =
        if col == [ ] then
          "ok"
        else
          "FAIL: hotkey(s) ${toString col} are also Plasma default global shortcuts and the default owner is not set to none";
    };

  report =
    h:
    let
      vs = lib.filterAttrs (_: kdeOn) (variantsOf flake.nixosConfigurations.${h});
    in
    lib.concatLists (
      lib.mapAttrsToList
        (
          n: c:
          lib.mapAttrsToList
            (k: v: {
              label = "${h}/${n}: ${k}";
              result = v;
            })
            (checksOf c)
        )
        vs
    );

  fx = import ../../lib/fixture-host.nix flake;
  fixture = fx.mkNixos [{ myconfig.programs.kde.enable = true; }];
  fixtureUser = fixture.config.myconfig.constants.user;
  fixtureShortcuts = (hmOf fixture.config).programs.plasma.shortcuts;
  fixtureCommands = (hmOf fixture.config).programs.plasma.hotkeys.commands;
  twinShortcuts =
    shortcuts:
    (fixture.extendModules {
      modules = [
        { home-manager.users.${fixtureUser}.programs.plasma.shortcuts = lib.mkOverride 10 shortcuts; }
      ];
    }).config;

  renamed = lib.mapAttrs'
    (
      g: v: lib.nameValuePair (if lib.hasSuffix ".desktop" g then "services/${g}" else g) v
    )
    fixtureShortcuts;
  released = renamed // {
    plasmashell = (renamed.plasmashell or { }) // {
      show-on-mouse-pos = "none";
    };
    "services/org.kde.plasma.emojier.desktop" = {
      _launch = "none";
    };
  };
  fixed = twinShortcuts released;
  fixedSc = (hmOf fixed).programs.plasma.shortcuts;
  fixedCmds = (hmOf fixed).programs.plasma.hotkeys.commands;

  plantedTwin = twinShortcuts (
    fixtureShortcuts
    // {
      kwin = (fixtureShortcuts.kwin or { }) // {
        ${layoutSwitcherAction} = "none";
      };
    }
  );
  doubledTwin = twinShortcuts (
    fixtureShortcuts
    // {
      "org.kde.spectacle.desktop"._launch = "none";
      "services/org.kde.spectacle.desktop"._launch = "Print";
    }
  );

  planted = {
    kwin = {
      ${layoutSwitcherAction} = "none";
    };
  };

  controls = [
    {
      label = "control: services/-prefixed groups pass";
      result =
        if !(kdeOn fixed) then
          "FAIL: twin lost KDE, control is vacuous"
        else if fixedSc == { } then
          "FAIL: twin has no shortcuts, control is vacuous"
        else if groupProblems fixedSc == [ ] then
          "ok"
        else
          "FAIL: prefixed twin still flagged: ${toString (groupProblems fixedSc)}";
    }
    {
      label = "control: twin with a doubled legacy and services/ group fails the group check";
      result =
        if (checksOf doubledTwin)."legacy .desktop groups migrate cleanly into services/" == "ok" then
          "FAIL: planted doubled group passed the fixture check"
        else
          "ok";
    }
    {
      label = "control: twin with the layout switcher under kwin fails the kwin check";
      result =
        if (checksOf plantedTwin)."${layoutSwitcherAction} is not filed under kwin" == "ok" then
          "FAIL: planted kwin switcher entry passed the fixture check"
        else
          "ok";
    }
    {
      label = "control: legacy-only .desktop group is accepted";
      result =
        if groupProblems { "org.kde.spectacle.desktop"._launch = "none"; } == [ ] then
          "ok"
        else
          "FAIL: legacy group without a services/ twin flagged";
    }
    {
      label = "control: same desktop id in legacy and services/ form is flagged";
      result =
        if
          groupProblems
            {
              "org.kde.spectacle.desktop"._launch = "none";
              "services/org.kde.spectacle.desktop"._launch = "Print";
            } == [ "org.kde.spectacle.desktop" ]
        then
          "ok"
        else
          "FAIL: planted doubled group not flagged";
    }
    {
      label = "control: comma key in a legacy .desktop group is flagged";
      result =
        if
          groupProblems { "org.kde.krunner.desktop"._launch = "Meta+,"; } == [ "org.kde.krunner.desktop" ]
        then
          "ok"
        else
          "FAIL: planted comma key not flagged";
    }
    {
      label = "control: released defaults pass the collision check";
      result =
        let
          bare = collisionsWith defaultOwners [ ] fixtureShortcuts fixtureCommands;
          rel = collisionsWith defaultOwners [ ] fixedSc fixedCmds;
        in
        if bare == [ ] then
          "FAIL: fixture hotkeys do not use Meta+V / Meta+., release control is vacuous"
        else if rel == [ ] then
          "ok"
        else
          "FAIL: twin with released defaults still collides: ${toString rel}";
    }
    {
      label = "control: collision check sees Meta+V and Meta+. when not allow-listed or released";
      result =
        let
          cmds = {
            a.key = "Meta+V";
            b.key = "Meta+.";
          };
          r = collisionsWith defaultOwners [ ] { } cmds;
        in
        if
          r == [
            "meta+v"
            "meta+."
          ]
        then
          "ok"
        else
          "FAIL: planted unreleased defaults gave ${toString r}";
    }
    {
      label = "control: allow-listed Meta+V and Meta+. pass";
      result =
        let
          cmds = {
            a.key = "Meta+V";
            b.key = "Meta+.";
          };
        in
        if collisions { } cmds == [ ] then
          "ok"
        else
          "FAIL: allow-listed pair flagged: ${toString (collisions { } cmds)}";
    }
    {
      label = "control: allow-list entry no longer applies when the default owner differs";
      result =
        let
          owners = defaultOwners // {
            "meta+v" = {
              group = "plasmashell";
              action = "other-action";
            };
          };
          r = collisionsWith owners allowedClashes { } { a.key = "Meta+V"; };
        in
        if r == [ "meta+v" ] then
          "ok"
        else
          "FAIL: stale allow-list entry still excused the clash: ${toString r}";
    }
    {
      label = "control: a new clash with a Plasma default (invented key) still fails";
      result =
        let
          owners = defaultOwners // {
            "meta+f12" = {
              group = "plasmashell";
              action = "invented-action";
            };
          };
          r = collisionsWith owners allowedClashes { } {
            a.key = "Meta+F12";
            b.key = "Meta+V";
          };
        in
        if r == [ "meta+f12" ] then "ok" else "FAIL: invented clash result: ${toString r}";
    }
    {
      label = "control: a released invented default passes";
      result =
        let
          owners = defaultOwners // {
            "meta+f12" = {
              group = "plasmashell";
              action = "invented-action";
            };
          };
          r = collisionsWith owners allowedClashes { plasmashell.invented-action = "none"; } {
            a.key = "Meta+F12";
          };
        in
        if r == [ ] then "ok" else "FAIL: released invented default flagged: ${toString r}";
    }
    {
      label = "control: layout switcher under kwin is flagged";
      result =
        if switcherMisplaced planted then "ok" else "FAIL: planted kwin switcher entry not flagged";
    }
    {
      label = "control: layout switcher in its own component is accepted";
      result =
        if switcherMisplaced { ${layoutSwitcherComponent}.${layoutSwitcherAction} = "none"; } then
          "FAIL: correct component flagged"
        else
          "ok";
    }
  ];

  render = rs: lib.concatMapStrings (r: "${r.label}\t${r.result}\n") rs;
in
{
  report = render (
    lib.mapAttrsToList
      (k: v: {
        label = "fixture: ${k}";
        result = v;
      })
      (checksOf fixture.config)
    ++ [
      {
        label = "fixture: KDE enabled with shortcuts and Meta+V / Meta+. hotkeys";
        result =
          if !(kdeOn fixture.config) then
            "FAIL: fixture lost KDE, every positive check would be vacuous"
          else if fixtureShortcuts == { } then
            "FAIL: fixture has no plasma shortcuts"
          else if
            !(lib.any (c: lib.toLower (c.key or "") == "meta+v") (lib.attrValues fixtureCommands))
            || !(lib.any (c: lib.toLower (c.key or "") == "meta+.") (lib.attrValues fixtureCommands))
          then
            "FAIL: fixture has no hotkey on Meta+V / Meta+., the collision check would be vacuous"
          else
            "ok";
      }
    ]
    ++ lib.concatMap report hostNames
  );
  control = render controls;
}
