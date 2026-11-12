{ lib }:
let
  nonEmpty = text: lib.filter (l: lib.trim l != "") (lib.splitString "\n" text);
  sortedChord = sep: s: lib.concatStringsSep "+" (lib.sort (a: b: a < b) (map (x: lib.toLower (lib.trim x)) (lib.splitString sep s)));
  dups = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);

  luaCalls = text:
    lib.concatMap
      (l:
        let m = builtins.match ''hl\.(unbind|bind)\("([^"]*)".*'' (lib.trim l); in
        lib.optional (m != null) { kind = builtins.elemAt m 0; chord = sortedChord " + " (builtins.elemAt m 1); })
      (nonEmpty text);

  niriChords = text:
    lib.concatMap
      (l:
        let m = builtins.match "    ([^ ]+) .*[{].*[}].*" l; in
        lib.optional (m != null) (sortedChord "+" (builtins.head m)))
      (nonEmpty text);

  mangoTypes = [ "bind" "bindl" "bindsl" "mousebind" "axisbind" "gesturebind" ];
  mangoLines = text:
    lib.concatMap
      (l:
        let
          t = lib.findFirst (t: lib.hasPrefix "${t}=" l) null mangoTypes;
          fields = lib.splitString "," (lib.removePrefix "${t}=" l);
        in
        lib.optional (t != null) { type = t; inherit fields; })
      (nonEmpty text);
  mangoIds = text: map (b: "${b.type}:${sortedChord "+" (builtins.elemAt b.fields 0)}:${lib.toLower (builtins.elemAt b.fields 1)}${lib.optionalString (b.type == "gesturebind") ":${builtins.elemAt b.fields 2}"}") (mangoLines text);
  mangoSpawnCommaFree = text:
    lib.all (b: !(lib.elem (builtins.elemAt b.fields 2) [ "spawn" "spawn_shell" ]) || lib.length b.fields == 4) (mangoLines text);

  luaPairingOk = text:
    let c = luaCalls text; in
    c != [ ] && lib.length c == 2 * (lib.length c / 2)
    && lib.all (i: (builtins.elemAt c (2 * i)).kind == "unbind" && (builtins.elemAt c (2 * i + 1)).kind == "bind" && (builtins.elemAt c (2 * i)).chord == (builtins.elemAt c (2 * i + 1)).chord)
      (lib.range 0 (lib.length c / 2 - 1));
  luaBindChords = text: map (c: c.chord) (lib.filter (c: c.kind == "bind") (luaCalls text));

  legacyWords = [ "vicinae" "swayosd" "swaync" "waybar" "grimblast" ];
  legacyHits = text: lib.filter (w: lib.hasInfix w text) legacyWords;

  bareTools = [ "install" "rm" "cp" "chown" "chmod" "mkdir" "ln" "mv" "cat" "sed" "mktemp" "jq" "flock" ];
  bareToolLines = text: lib.filter (l: let t = lib.trim l; in lib.any (w: lib.hasPrefix "${w} " t) bareTools) (lib.splitString "\n" text);
in
{
  inherit dups luaCalls luaBindChords luaPairingOk niriChords mangoIds mangoSpawnCommaFree legacyHits bareToolLines;
}
