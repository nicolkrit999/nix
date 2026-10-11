d:
let
  tryS =
    e:
    let
      r = builtins.tryEval (builtins.deepSeq e e);
    in
    if r.success then
      {
        ok = true;
        v = r.value;
      }
    else
      { ok = false; };

  nameOf =
    p:
    if builtins.isAttrs p then
      builtins.unsafeDiscardStringContext (p.pname or (builtins.parseDrvName p.name).name)
    else
      (builtins.parseDrvName (builtins.substring 33 (-1) (builtins.unsafeDiscardStringContext (builtins.baseNameOf p)))).name;
  inputsOf = s: (s.nativeBuildInputs or [ ]) ++ (s.buildInputs or [ ]);
  named = s: n: builtins.filter (p: nameOf p == n) (inputsOf s);

  summarize = s: {
    drv = tryS s.drvPath;
    pkgs = tryS (map nameOf (inputsOf s));
    firstPkg = tryS (
      let
        p = builtins.head (inputsOf s);
      in
      {
        name = nameOf p;
        version = if builtins.isAttrs p then p.version or "" else "";
        paths = if builtins.isAttrs p then map nameOf (p.paths or [ ]) else [ ];
      }
    );
    goVersion = tryS (map (p: p.version) (named s "go"));
    lombokOut = tryS (map (p: toString p) (named s "lombok"));
    shellHook = tryS (s.shellHook or "");
    postShellHook = tryS (s.postShellHook or "");
    javaHome = tryS (s.JAVA_HOME or "");
    javaToolOptions = tryS (s.JAVA_TOOL_OPTIONS or s.env.JAVA_TOOL_OPTIONS or "");
    rustSrcPath = tryS (s.RUST_SRC_PATH or s.env.RUST_SRC_PATH or "");
  };
in
builtins.mapAttrs (_sys: shells: builtins.mapAttrs (_n: summarize) shells) d
