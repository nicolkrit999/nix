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

  kxkbValue =
    c: key:
    let
      layout = (hmOf c).programs.plasma.configFile.kxkbrc.Layout or { };
    in
    layout.${key}.value or null;

  same =
    what: got: want:
    if got == want then
      "ok"
    else
      "FAIL: kxkbrc ${what} is ${if got == null then "unset" else "\"${got}\""}, expected \"${want}\"";

  sameOrUnset = what: got: want: if got == null then "ok" else same what got want;

  checksOf =
    c:
    let
      k = c.myconfig.constants;
    in
    {
      "kxkbrc LayoutList == constants.keyboardLayout" = same "LayoutList" (kxkbValue c "LayoutList") k.keyboardLayout;
      "kxkbrc VariantList == constants.keyboardVariant" = same "VariantList" (kxkbValue c "VariantList") k.keyboardVariant;
      "kxkbrc Options unset or == constants.keyboardOptions" = sameOrUnset "Options" (kxkbValue c "Options") k.keyboardOptions;
      "kxkbrc LayoutList == services.xserver.xkb.layout" = same "LayoutList" (kxkbValue c "LayoutList") c.services.xserver.xkb.layout;
      "kxkbrc VariantList == services.xserver.xkb.variant" = same "VariantList" (kxkbValue c "VariantList") c.services.xserver.xkb.variant;
    };

  report =
    h:
    let
      vs = lib.filterAttrs (_: kdeOn) (variantsOf flake.nixosConfigurations.${h});
    in
    lib.concatLists (
      lib.mapAttrsToList (
        n: c: lib.mapAttrsToList (k: v: { label = "${h}/${n}: ${k}"; result = v; }) (checksOf c)
      ) vs
    );

  kdeVariants = lib.concatMap (
    h: lib.attrNames (lib.filterAttrs (_: kdeOn) (variantsOf flake.nixosConfigurations.${h}))
  ) hostNames;

  ctl = flake.nixosConfigurations.nixos-desktop;
  twin = constants: (ctl.extendModules { modules = [ { myconfig.constants = constants; } ]; }).config;
  force = lib.mkForce;

  twinFollows =
    label: constants: key: want:
    let
      c = twin constants;
    in
    {
      inherit label;
      result =
        if !(kdeOn c) then "FAIL: twin lost KDE, control is vacuous" else same key (kxkbValue c key) want;
    };

  controls = [
    (twinFollows "control: LayoutList follows constants.keyboardLayout" {
      keyboardLayout = force "us,de";
      keyboardVariant = force ",";
    } "LayoutList" "us,de")
    (twinFollows "control: VariantList follows constants.keyboardVariant" {
      keyboardLayout = force "us,de";
      keyboardVariant = force "intl,";
    } "VariantList" "intl,")
    {
      label = "control: comparator rejects a mismatch";
      result = if same "Options" "grp:alt_shift_toggle" "grp:ctrl_alt_toggle" == "ok" then "FAIL: mismatch accepted" else "ok";
    }
    {
      label = "control: unset-tolerant comparator still rejects a mismatch";
      result = if sameOrUnset "Options" "grp:alt_shift_toggle" "grp:ctrl_alt_toggle" == "ok" then "FAIL: mismatch accepted" else "ok";
    }
    {
      label = "control: unset-tolerant comparator accepts an unset value";
      result = if sameOrUnset "Options" null "grp:ctrl_alt_toggle" == "ok" then "ok" else "FAIL: unset rejected";
    }
    {
      label = "control: comparator rejects an unset value";
      result = if same "Options" null "grp:ctrl_alt_toggle" == "ok" then "FAIL: unset accepted" else "ok";
    }
  ];

  render = rs: lib.concatMapStrings (r: "${r.label}\t${r.result}\n") rs;
in
{
  report = render (
    lib.concatMap report hostNames
    ++ [
      {
        label = "at least one KDE variant evaluated";
        result = if kdeVariants != [ ] then "ok" else "FAIL: no variant enables KDE, every positive check would be vacuous";
      }
    ]
  );
  control = render controls;
}
