{ lib }:
let
  trim = lib.strings.trim;
  join = lib.concatStringsSep;
  lines = ls: (join "\n" ls) + "\n";

  quote = s: "\"${builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s}\"";

  hyprKeyNames = {
    return = "Return";
    space = "Space";
    left = "Left";
    right = "Right";
    up = "Up";
    down = "Down";
  };

  hyprChord = chord:
    let
      tokens = map trim (lib.splitString "+" chord);
      last = lib.last tokens;
      key = hyprKeyNames.${last} or last;
    in
    join " + " ((lib.init tokens) ++ [ key ]);

  luaValue = v:
    if builtins.isBool v then (if v then "true" else "false")
    else if builtins.isInt v then toString v
    else quote v;

  luaFlags = flags:
    "{ ${join ", " (lib.mapAttrsToList (k: v: "${k} = ${luaValue v}") flags)} }";

  hyprBind = b:
    let
      args = b._args;
      chord = hyprChord (builtins.elemAt args 0);
      disp = (builtins.elemAt args 1).expr;
      flags = if builtins.length args > 2 then ", ${luaFlags (builtins.elemAt args 2)}" else "";
    in
    [
      "hl.unbind(${quote chord})"
      "hl.bind(${quote chord}, ${disp}${flags})"
    ];

  kdlValue = v:
    if builtins.isBool v then (if v then "true" else "false")
    else if builtins.isInt v then toString v
    else if builtins.isFloat v then toString v
    else quote v;

  kdlProps = props: join " " (lib.mapAttrsToList (k: v: "${k}=${kdlValue v}") props);

  niriAction = action:
    let
      name = builtins.head (builtins.attrNames action);
      v = action.${name};
    in
    if builtins.isList v then (if v == [ ] then "${name};" else "${name} ${join " " (map kdlValue v)};")
    else if builtins.isAttrs v then "${name} ${kdlProps v};"
    else "${name} ${kdlValue v};";

  niriBind = chord: bind:
    let
      props = removeAttrs bind [ "action" ];
      propStr = lib.optionalString (props != { }) " ${kdlProps props}";
      name = builtins.replaceStrings [ "Mod+" ] [ "Super+" ] chord;
    in
    "    ${name}${propStr} { ${niriAction bind.action} }";

  mangoKeyNames = {
    Space = "space";
    BracketLeft = "bracketleft";
    BracketRight = "bracketright";
  };

  mangoKey = k:
    if builtins.stringLength k == 1 then lib.toLower k else mangoKeyNames.${builtins.unsafeDiscardStringContext k} or k;

  mangoLine = type: line:
    let
      parts = lib.splitString "," line;
      fixed = [ (builtins.elemAt parts 0) (mangoKey (builtins.elemAt parts 1)) ] ++ (lib.drop 2 parts);
    in
    "${type}=${join "," fixed}";

  header = prefix: [
    "${prefix} Written by the NixOS config (specializations.ryokuBinds). The file is replaced on every rebuild;"
    "${prefix} change the binds in the Nix modules (or the host's extraBinds), not here."
  ];
in
{
  hyprland = binds: lines (
    (header "--") ++ [ "" ] ++ lib.concatMap hyprBind binds
  );

  niri = binds: lines (
    (header "//") ++ [ "" "binds {" ]
    ++ lib.mapAttrsToList niriBind binds
    ++ [ "}" ]
  );

  mango = { bind, bindl, bindsl, mousebind, axisbind, gesturebind }: lines (
    (header "#") ++ [ "" ]
    ++ map (mangoLine "bind") bind
    ++ map (mangoLine "bindl") bindl
    ++ map (mangoLine "bindsl") bindsl
    ++ map (l: "mousebind=${l}") mousebind
    ++ map (l: "axisbind=${l}") axisbind
    ++ map (l: "gesturebind=${l}") gesturebind
  );
}
