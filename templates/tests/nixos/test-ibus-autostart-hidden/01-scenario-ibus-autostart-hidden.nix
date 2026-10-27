let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  entry = "autostart/ibus-daemon.desktop";
  hostNames = [
    "nixos-desktop"
    "nixos-laptop"
  ];

  variantsOf =
    sys:
    let
      base = sys.config;
    in
    { inherit base; } // lib.mapAttrs (_: s: s.configuration) base.specialisation;

  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
  files = c: (hmOf c).xdg.configFile;
  ibusOn = c: c.i18n.inputMethod.enable && c.i18n.inputMethod.type == "ibus";
  gnomeOn = c: c.myconfig.programs.gnome.enable;

  hiddenOk =
    text:
    let
      ls = map lib.trim (lib.splitString "\n" text);
    in
    lib.elem "[Desktop Entry]" ls && lib.elem "Hidden=true" ls && !(lib.elem "Hidden=false" ls);

  ibusNames = c: lib.filter (lib.hasInfix "ibus") (builtins.attrNames (files c));

  gnomeChecks =
    c:
    let
      present = files c ? ${entry};
    in
    {
      "ibus is on under GNOME" =
        if ibusOn c then
          "ok"
        else
          "FAIL: GNOME enabled but ibus is off, the premise of the override is gone";
      "override file exists" =
        if present then "ok" else "FAIL: no ${entry} in home-manager xdg.configFile";
      "override has Hidden=true" =
        if present && hiddenOk (files c).${entry}.text then
          "ok"
        else
          "FAIL: ${entry} text lacks Hidden=true";
      "only the exact ibus-daemon.desktop name is defined" =
        if ibusNames c == [ entry ] then "ok" else "FAIL: ibus autostart names: ${toString (ibusNames c)}";
    };

  anyChecks = c: {
    "no kde-ibus-kill autostart" =
      if lib.any (lib.hasInfix "kde-ibus-kill") (builtins.attrNames (files c)) then
        "FAIL: kde-ibus-kill autostart is back"
      else
        "ok";
    "override only with GNOME and ibus" =
      let
        want = gnomeOn c && ibusOn c;
      in
      if (files c ? ${entry}) == want then
        "ok"
      else
        "FAIL: override present=${
          lib.boolToString (files c ? ${entry})
        }, expected ${lib.boolToString want}";
  };

  fx = import ../../lib/fixture-host.nix flake;
  fixture = mods: (fx.mkNixos mods).config;

  hostReport =
    h:
    lib.concatLists (
      lib.mapAttrsToList (
        n: c:
        lib.mapAttrsToList (k: v: {
          label = "${h}/${n}: ${k}";
          result = v;
        }) (anyChecks c)
      ) (variantsOf flake.nixosConfigurations.${h})
    );

  gnomeFixture = fixture [ { myconfig.programs.gnome.enable = true; } ];

  positives = lib.mapAttrsToList (k: v: {
    label = "fixture GNOME: ${k}";
    result = v;
  }) (gnomeChecks gnomeFixture // anyChecks gnomeFixture);

  twin = mod: fixture [ { myconfig.programs.gnome.enable = true; } mod ];

  absentIf =
    what: c: if !(files c ? ${entry}) then "ok" else "FAIL: override still defined with ${what}";

  controls = [
    {
      label = "control: fixture without GNOME has no override";
      result = absentIf "GNOME off" (fixture [ ]);
    }
    {
      label = "control: ibus disabled drops the override";
      result = absentIf "ibus disabled" (twin {
        i18n.inputMethod.enable = lib.mkForce false;
      });
    }
    {
      label = "control: non-ibus input method drops the override";
      result = absentIf "fcitx5" (twin {
        i18n.inputMethod.type = lib.mkForce "fcitx5";
      });
    }
    {
      label = "control: GNOME forced off (ibus forced on) drops the override";
      result =
        let
          c = fixture [{
            myconfig.programs.gnome.enable = lib.mkForce false;
            i18n.inputMethod.enable = lib.mkForce true;
            i18n.inputMethod.type = lib.mkForce "ibus";
          }];
        in
        if gnomeOn c then
          "FAIL: twin still has GNOME on, control is vacuous"
        else if !(ibusOn c) then
          "FAIL: twin has ibus off, control would pass for the wrong reason"
        else
          absentIf "GNOME off and ibus on" c;
    }
    {
      label = "control: Hidden=false text is rejected";
      result =
        if hiddenOk "[Desktop Entry]\nHidden=false\n" then "FAIL: planted Hidden=false accepted" else "ok";
    }
    {
      label = "control: text without Hidden is rejected";
      result =
        if hiddenOk "[Desktop Entry]\nType=Application\n" then
          "FAIL: planted text without Hidden accepted"
        else
          "ok";
    }
  ];

  render = rs: lib.concatMapStrings (r: "${r.label}\t${r.result}\n") rs;
in
{
  report = render (positives ++ lib.concatMap hostReport hostNames);
  control = render controls;
}
