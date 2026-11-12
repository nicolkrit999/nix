{ lib }:
rec {
  base = v: if builtins.isAttrs v && v ? cmd then v.cmd else v;

  isShell = v: let b = base v; in builtins.isAttrs b && b ? sh;

  asLine = v:
    let b = base v; in
    if builtins.isString b then b
    else if builtins.isList b then lib.concatStringsSep " " b
    else b.sh;

  asArgv = v:
    let b = base v; in
    if builtins.isList b then b
    else if builtins.isString b then lib.splitString " " b
    else [ "sh" "-c" b.sh ];

  hyprGlobal = v: if builtins.isAttrs v then v.hyprGlobal or null else null;
}
