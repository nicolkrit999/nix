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

  widgetNames = [
    "org.kde.plasma.kickoff"
    "org.kde.plasma.icontasks"
    "org.kde.plasma.pager"
    "org.kde.plasma.panelspacer"
    "org.kde.plasma.systemtray"
    "org.kde.plasma.digitalclock"
    "org.kde.plasma.showdesktop"
  ];

  squash = lib.replaceStrings [ " " "\n" ] [ "" "" ];
  count = needle: text: builtins.length (lib.splitString needle text) - 1;
  scriptOf = c: ((hmOf c).programs.plasma.startup.desktopScript."panels" or { text = ""; }).text;
  panelsOf = c: (hmOf c).programs.plasma.panels;

  loopHead = "for (screenID = 0; screenID < screenCount; screenID++)";

  verdict = problems: if problems == [ ] then "ok" else "FAIL: ${lib.concatStringsSep "; " problems}";

  checksOf =
    c:
    let
      text = scriptOf c;
      panels = panelsOf c;
      pinned = c.myconfig.programs.kde.pinnedApps;
      each = needle: want: if count needle text == want then [ ] else [ "${toString (count needle text)}x \"${needle}\" in the panel script, want ${toString want}" ];
    in
    {
      "one panel entry set to screen all" = verdict (
        if builtins.length panels != 1 then
          [ "${toString (builtins.length panels)} panel entries, want 1" ]
        else if (builtins.head panels).screen != "all" then
          [ "screen is ${builtins.toJSON (builtins.head panels).screen}, want \"all\"" ]
        else
          [ ]
      );
      "script loops over every screen and creates the panel inside the loop" = verdict (
        (each loopHead 1)
        ++ (each "new Panel()" 1)
        ++ (
          if lib.hasInfix (squash "${loopHead}{constpanel=newPanel();") (squash text) then
            [ ]
          else
            [ "new Panel() is not the first statement of the screen loop body" ]
        )
        ++ (each "lastScreen[$i]\", screenID" 1)
      );
      "same height, location, hiding and floating on every panel" = verdict (
        (each "panel.height = 44;" 1)
        ++ (each "panel.location = \"bottom\";" 1)
        ++ (each "panel.hiding = \"autohide\";" 1)
        ++ (each "panel.floating = false;" 1)
      );
      "all widgets present once in the shared panel body" = verdict (
        (lib.concatMap (w: each "panel.addWidget(\"${w}\")" 1) widgetNames)
        ++ (each "panel.addWidget(" (builtins.length widgetNames))
      );
      "pinned launchers present in the shared panel body" = verdict (
        lib.concatMap (a: each "applications:${a}" 1) pinned
      );
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
  fixtureWith =
    extra:
    (fx.mkNixos [
      (
        {
          myconfig.programs.kde.enable = true;
          myconfig.programs.kde.pinnedApps = [
            "org.kde.dolphin.desktop"
            "kitty.desktop"
          ];
        }
        // extra
      )
    ]).config;
  fixture = fixtureWith { };
  fixtureUser = fixture.myconfig.constants.user;
  twin =
    modules:
    (flake.nixosConfigurations.template-host-minimal.extendModules {
      modules = [
        {
          myconfig.programs.kde.enable = true;
          myconfig.programs.kde.pinnedApps = [ "org.kde.dolphin.desktop" ];
        }
      ] ++ modules;
    }).config;
  singleScreenTwin = twin [
    {
      home-manager.users.${fixtureUser}.programs.plasma.panels = lib.mkForce [
        {
          screen = 0;
          location = "bottom";
          height = 44;
          floating = false;
          hiding = "autohide";
          widgets = widgetNames;
        }
      ];
    }
  ];
  noKdeTwin = twin [{ myconfig.programs.kde.enable = lib.mkForce false; }];

  fixtureChecks = checksOf fixture;
  notOk = v: v != "ok";

  controls = [
    {
      label = "control: fixture has KDE on with two pinned apps";
      result =
        if !(kdeOn fixture) then
          "FAIL: fixture lost KDE, every positive check would be vacuous"
        else if fixture.myconfig.programs.kde.pinnedApps == [ ] then
          "FAIL: no pinned apps, launcher check is vacuous"
        else if scriptOf fixture == "" then
          "FAIL: empty panel script"
        else
          "ok";
    }
    {
      label = "control: a panel pinned to screen 0 fails the all-screens checks";
      result =
        let
          cs = checksOf singleScreenTwin;
        in
        if !(kdeOn singleScreenTwin) then
          "FAIL: twin lost KDE"
        else if
          notOk cs."one panel entry set to screen all" && notOk cs."script loops over every screen and creates the panel inside the loop"
        then
          "ok"
        else
          "FAIL: single-screen panel passed the per-screen checks";
    }
    {
      label = "control: KDE disabled gives no panels and no panel script";
      result =
        if kdeOn noKdeTwin then
          "FAIL: twin still has KDE"
        else if panelsOf noKdeTwin != [ ] then
          "FAIL: ${toString (builtins.length (panelsOf noKdeTwin))} panel(s) with KDE disabled"
        else if scriptOf noKdeTwin != "" then
          "FAIL: panel script generated with KDE disabled"
        else
          "ok";
    }
    {
      label = "control: without pinned apps the script has no launchers";
      result =
        let
          bare = twin [{ myconfig.programs.kde.pinnedApps = lib.mkForce [ ]; }];
        in
        if !(kdeOn bare) then
          "FAIL: twin lost KDE"
        else if scriptOf bare == "" then
          "FAIL: twin has no panel script"
        else if count "applications:" (scriptOf bare) != 0 then
          "FAIL: launchers present without pinned apps"
        else if count "applications:" (scriptOf fixture) == 0 then
          "FAIL: fixture has no launchers, the positive check is vacuous"
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
        result = if kdeOn fixture then v else "FAIL: fixture lost KDE, check is vacuous";
      })
      fixtureChecks
    ++ lib.concatMap report hostNames
  );
  control = render controls;
}
