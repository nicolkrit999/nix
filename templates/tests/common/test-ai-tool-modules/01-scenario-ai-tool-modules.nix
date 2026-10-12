let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  inherit (flake) inputs;

  hasNixos = flake.nixosConfigurations != { };
  guard = body: if hasNixos then body else "ok";

  probe = { lib, pkgs, ... }: {
    options.testProbe = lib.mkOption { type = lib.types.raw; };
    config.testProbe = { inherit (pkgs) codex; };
  };

  mk = mods: flake.nixosConfigurations.template-host-minimal.extendModules {
    modules = [ probe ] ++ mods;
  };

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  all = results:
    let bad = lib.filter (r: r != "ok") results;
    in if bad == [ ] then "ok" else lib.concatStringsSep "; " bad;

  nc = builtins.unsafeDiscardStringContext;
  hmOf = x: x.config.home-manager.users.krit;

  headroomOn = mk [{ myconfig.programs.headroom.enable = true; }];
  headroomOff = mk [{ myconfig.programs.headroom.enable = false; }];

  headroom =
    let
      h = hmOf headroomOn;
      unit = h.systemd.user.services.headroom-proxy or null;
      execStart = if unit == null then "" else nc (toString unit.Service.ExecStart);
      execMatch = builtins.match "(/nix/store/[^ ]+)/bin/headroom proxy (.*)" execStart;
      pkgPath = if execMatch == null then null else builtins.elemAt execMatch 0;
      args = if execMatch == null then "" else builtins.elemAt execMatch 1;
      portMatch = builtins.match ".*--port ([0-9]+).*" args;
      port = if portMatch == null then null else builtins.head portMatch;
      hostMatch = builtins.match ".*--host ([^ ]+).*" args;
      byName = n: lib.filter (p: (p.name or "") == n || (p.pname or "") == n) h.home.packages;
      script = byName "headroom-claude";
      scriptText = if script == [ ] then "" else nc ((builtins.head script).text or "");
      pkg = lib.filter (p: nc p.outPath == pkgPath) h.home.packages;
      offNames = map (p: nc p.outPath) (hmOf headroomOff).home.packages;
      added = lib.filter (p: !(builtins.elem (nc p.outPath) offNames)) h.home.packages;
      isPyEnv = p: builtins.match "python3?-[0-9.]+-env" (p.name or "") != null || p ? pythonPath && p ? env;
      after = if unit == null then [ ] else lib.toList (unit.Unit.After or [ ]);
    in
    {
      check-unit-present = if unit == null then "FAIL: headroom-proxy user unit missing" else
      expect "headroom-proxy WantedBy" unit.Install.WantedBy [ "default.target" ];

      check-unit-off-absent = expect "headroom-proxy unit with headroom disabled"
        ((hmOf headroomOff).systemd.user.services ? headroom-proxy)
        false;

      check-execstart-port =
        if execMatch == null then "FAIL: ExecStart is not <store>/bin/headroom proxy ...: ${execStart}"
        else expect "ExecStart --port" port "8787";

      check-execstart-host-loopback =
        if execMatch == null then "FAIL: ExecStart unparsable: ${execStart}"
        else if hostMatch == null then "ok"
        else expect "ExecStart --host" (builtins.head hostMatch) "127.0.0.1";

      check-script-probe-address =
        if scriptText == "" then "FAIL: headroom-claude script missing from home.packages"
        else if port == null then "FAIL: no port parsed from ExecStart"
        else if lib.hasInfix "/dev/tcp/127.0.0.1/${port}" scriptText then "ok"
        else "FAIL: headroom-claude does not probe /dev/tcp/127.0.0.1/${port}";

      check-script-base-url =
        if scriptText == "" then "FAIL: headroom-claude script missing from home.packages"
        else if port == null then "FAIL: no port parsed from ExecStart"
        else
          all [
            (if lib.hasInfix "ANTHROPIC_BASE_URL=\"http://127.0.0.1:${port}\"" scriptText then "ok"
            else "FAIL: ANTHROPIC_BASE_URL is not http://127.0.0.1:${port}")
            (if lib.hasInfix "localhost" scriptText || lib.hasInfix "0.0.0.0" scriptText
            then "FAIL: headroom-claude names localhost/0.0.0.0" else "ok")
          ];

      check-unit-no-network-target = expect "headroom-proxy Unit.After contains network.target"
        (builtins.elem "network.target" after)
        false;

      check-package-is-application =
        if builtins.length pkg != 1 then "FAIL: ExecStart package ${toString pkgPath} not exactly once in home.packages"
        else
          all [
            (expect "headroom pythonModule" ((builtins.head pkg).pythonModule or null) false)
            (expect "headroom pname" ((builtins.head pkg).pname or null) "headroom-ai")
          ];

      check-no-python-env-added =
        let envs = lib.filter isPyEnv added;
        in if added == [ ] then "FAIL: headroom adds no home.packages (control)"
        else if envs == [ ] then "ok"
        else "FAIL: headroom adds python env(s): ${toString (map (p: p.name) envs)}";
    };

  ccOn = mk [{ myconfig.programs.claude-code.enable = true; }];
  ccCowork = mk [{ myconfig.programs.claude-code = { enable = true; cowork = true; }; }];
  ccOffCowork = mk [{ myconfig.programs.claude-code = { enable = false; cowork = true; }; }];

  coworkState = x: [
    x.config.services.claude-cowork.enable
    (x.config.systemd.user.services ? claude-cowork)
  ];

  cowork = {
    check-cowork-option-default = expect "claude-code.cowork option default"
      (ccOn.options.myconfig.programs.claude-code.cowork.default or null)
      false;

    check-cowork-default-off = all [
      (expect "claude-code.cowork value" ccOn.config.myconfig.programs.claude-code.cowork false)
      (expect "cowork service [enable, unit] with cowork unset" (coworkState ccOn) [ false false ])
    ];

    check-cowork-drives-service = expect "cowork service [enable, unit] with cowork = true"
      (coworkState ccCowork) [ true true ];

    check-cowork-needs-claude-code = expect "cowork service [enable, unit] with claude-code off"
      (coworkState ccOffCowork) [ false false ];
  };

  codexOn = mk [{ myconfig.programs.codex.enable = true; }];
  codexOff = mk [{ myconfig.programs.codex.enable = false; }];
  codexSrc = nc inputs.codex-cli-nix.outPath;
  fromOverlay = p: lib.hasPrefix "${codexSrc}/" (p.meta.position or "");

  codex = {
    check-codex-from-overlay =
      let p = codexOn.config.testProbe.codex;
      in if fromOverlay p then "ok"
      else "FAIL: pkgs.codex meta.position ${p.meta.position or "?"} is not in the codex-cli-nix input";

    check-codex-installed-is-overlay =
      let
        want = nc codexOn.config.testProbe.codex.drvPath;
        hits = lib.filter (p: nc (p.drvPath or "") == want) codexOn.config.environment.systemPackages;
      in
      expect "overlay codex in environment.systemPackages (count)" (builtins.length hits) 1;

    check-codex-version-matches-input = expect "codex version vs codex-cli-nix package"
      codexOn.config.testProbe.codex.version
      inputs.codex-cli-nix.packages.x86_64-linux.codex.version;

    check-codex-control-plain-nixpkgs =
      let p = codexOff.config.testProbe.codex;
      in if fromOverlay p then "FAIL: codex disabled but pkgs.codex still comes from the overlay (position check cannot discriminate)"
      else "ok";
  };
in
{
  headroom = lib.mapAttrs (_: guard) headroom;
  cowork = lib.mapAttrs (_: guard) cowork;
  codex = lib.mapAttrs (_: guard) codex;
}
