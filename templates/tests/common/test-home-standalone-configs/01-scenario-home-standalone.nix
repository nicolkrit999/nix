let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  homes = flake.homeConfigurations;
  nas = homes."krit@Nicol-NAS";
  nasCfg = nas.config;

  hasNixos = flake.nixosConfigurations != { };
  guard = body: if hasNixos then body else "ok";

  expect = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  isDrv = s: builtins.match "/nix/store/.*\\.drv" s != null;

  instantiates = name: home:
    let
      path = builtins.tryEval (builtins.unsafeDiscardStringContext home.config.home.path.drvPath);
      act = builtins.tryEval (builtins.unsafeDiscardStringContext home.activationPackage.drvPath);
    in
    if !path.success then "FAIL: ${name}: home.path.drvPath does not evaluate"
    else if !act.success then "FAIL: ${name}: activationPackage.drvPath does not evaluate"
    else if !(isDrv path.value && isDrv act.value) then "FAIL: ${name}: drvPath is not a .drv store path"
    else "ok";

  stableProbe =
    let
      x = nas.extendModules {
        modules = [
          ({ pkgsStable, ... }: {
            home.file."probe-stable-version".text = pkgsStable.lib.version;
            home.file."probe-stable-path".text = toString pkgsStable.path;
          })
        ];
      };
    in
    {
      version = x.config.home.file."probe-stable-version".text;
      path = x.config.home.file."probe-stable-path".text;
    };

  nc = builtins.unsafeDiscardStringContext;
  all = results:
    let bad = lib.filter (r: r != "ok") results;
    in if bad == [ ] then "ok" else lib.concatStringsSep "; " bad;

  probe = { lib, pkgs, ... }: {
    options.testProbe = lib.mkOption { type = lib.types.raw; };
    config.testProbe = { inherit (pkgs) claude-code codex hello; };
  };

  mcpSecretsFake = [{ sopsSecret = "test_mcp_secret"; envVar = "TEST_MCP_SECRET_VAR"; }];

  progs = on: nas.extendModules {
    modules = [
      probe
      ({ lib, pkgs, ... }: {
        myconfig.programs = {
          claude-code = {
            enable = lib.mkForce true;
            mcpSecrets = lib.mkForce mcpSecretsFake;
            mcpEnv = lib.mkForce { TEST_STATIC_MARKER = "static"; };
          };
          codex.enable = lib.mkForce on;
          herdr.enable = lib.mkForce on;
          nltchNur = {
            enable = lib.mkForce on;
            packages = lib.mkForce [ pkgs.hello ];
          };
          thunderbird = {
            enable = lib.mkForce true;
            accounts = lib.mkForce (lib.optional on {
              name = "test";
              addressLocalSecretName = "test_local";
              addressDomainSecretName = "test_domain";
              realName = "Test";
            });
          };
        };
        myconfig.krit.programs.claude-code-wrappers.enable = lib.mkForce false;
      })
    ];
  };
  progsOn = progs true;
  progsOff = progs false;

  drvs = x: map (p: nc (p.drvPath or "")) x.config.home.packages;
  hasDrv = x: d: builtins.elem (nc d.drvPath) (drvs x);
  fromInput = input: p: lib.hasPrefix "${nc input.outPath}/" (p.meta.position or "");

  homeCc = progsOn.config.testProbe.claude-code;
  claudeWrapper = lib.filter (p: (p.name or "") == "claude" && p ? text) progsOn.config.home.packages;
  wrapperText = if claudeWrapper == [ ] then "" else nc (builtins.head claudeWrapper).text;
  wrapperExports = lib.concatMap
    (l: let m = builtins.match "export ([A-Za-z_][A-Za-z0-9_]*)=.*" l; in if m == null then [ ] else m)
    (lib.splitString "\n" wrapperText);
  secretPaths = map (s: nc progsOn.config.sops.secrets.${s.sopsSecret}.path) mcpSecretsFake;

  aliasKeys = p:
    lib.concatMap (a: builtins.attrNames a) [
      (p.fish.shellAbbrs or { })
      (p.zsh.shellAliases or { })
      (p.bash.shellAliases or { })
    ];
  openrouterKeys = p: lib.filter (lib.hasPrefix "cai-openrouter-") (aliasKeys p);

  nixosCc = wrappers: flake.nixosConfigurations.template-host-minimal.extendModules {
    modules = [{
      myconfig.programs.claude-code.enable = true;
      myconfig.krit.programs.claude-code-wrappers.enable = wrappers;
    }];
  };

  nasNhCfg = nasCfg.myconfig.nh;
  nasFlakeDir = nasCfg.myconfig.constants.flakeDir;
  nixosNhOn = flake.nixosConfigurations.template-host-minimal.extendModules {
    modules = [ ({ lib, ... }: { myconfig.nh.enable = lib.mkForce true; }) ];
  };

  sidraKey = ".config/Sidra/custom-theme.json";
  sidraTwin = stylixOn: customTheme: nas.extendModules {
    modules = [
      ({ lib, ... }: {
        myconfig.programs.sidra = {
          enable = lib.mkForce true;
          customTheme = lib.mkForce customTheme;
        };
        myconfig.stylix.enable = lib.mkForce stylixOn;
      })
    ];
  };
  sidraTheme = x:
    let f = x.config.home.file;
    in if f ? ${sidraKey} && f.${sidraKey}.enable then builtins.fromJSON f.${sidraKey}.text else null;

  zenForced = base: base.extendModules {
    modules = [ ({ lib, ... }: { myconfig.programs.zen.browser.enable = lib.mkForce true; }) ];
  };
  zenNames = c: c.stylix.targets."zen-browser".profileNames;

  homePrograms = {
    check-claude-code-overlay-source =
      if fromInput flake.inputs.claude-code homeCc then "ok"
      else "FAIL: home pkgs.claude-code meta.position ${homeCc.meta.position or "?"} is not in the claude-code input";

    check-claude-code-version-matches-nixos = guard (
      expect "home vs NixOS pkgs.claude-code version"
        homeCc.version
        flake.nixosConfigurations.template-host-minimal.pkgs.claude-code.version
    );

    check-claude-wrapper-execs-overlay =
      if wrapperText == "" then "FAIL: no claude wrapper (name claude, .text) in home.packages"
      else if lib.hasInfix "exec ${nc homeCc.outPath}/bin/claude " wrapperText then "ok"
      else "FAIL: claude wrapper does not exec ${nc homeCc.outPath}/bin/claude";

    check-claude-binary-in-package = all [
      (expect "CLAUDE_BINARY" (nc progsOn.config.home.sessionVariables.CLAUDE_BINARY or "") "${nc homeCc.outPath}/bin/.claude-unwrapped")
      (if lib.hasInfix "$out/bin/.claude-unwrapped" (homeCc.installPhase or "") then "ok"
      else "FAIL: claude-code installPhase does not install $out/bin/.claude-unwrapped")
    ];

    check-claude-wrapper-no-secret-exports =
      if wrapperText == "" then "FAIL: no claude wrapper in home.packages"
      else
        all [
          (expect "wrapper exports (mcpEnv keys only)" wrapperExports [ "TEST_STATIC_MARKER" ])
          (if lib.any (needle: lib.hasInfix needle wrapperText) ([ "$(cat" "/run/secrets" ] ++ secretPaths)
          then "FAIL: claude wrapper reads a secret file" else "ok")
        ];

    check-openrouter-aliases-absent-without-wrappers = all [
      (if builtins.elem "caitempplugins" (aliasKeys progsOn.config.programs) then "ok" else "FAIL: caitempplugins alias missing (control)")
      (expect "home cai-openrouter-* aliases with wrappers off" (openrouterKeys progsOn.config.programs) [ ])
    ];

    check-codex-installed-when-enabled =
      let codex = progsOn.config.testProbe.codex;
      in all [
        (if fromInput flake.inputs.codex-cli-nix codex then "ok" else "FAIL: home pkgs.codex not from the codex-cli-nix overlay")
        (expect "codex in home.packages [on, off]" [ (hasDrv progsOn codex) (hasDrv progsOff progsOff.config.testProbe.codex) ] [ true false ])
      ];

    check-herdr-installed-when-enabled =
      let herdr = flake.inputs.herdr.packages.x86_64-linux.default;
      in expect "herdr in home.packages [on, off]" [ (hasDrv progsOn herdr) (hasDrv progsOff herdr) ] [ true false ];

    check-nltch-nur-installed-when-enabled = expect "nltchNur.packages in home.packages [on, off]"
      [ (hasDrv progsOn progsOn.config.testProbe.hello) (hasDrv progsOff progsOff.config.testProbe.hello) ]
      [ true false ];

    check-thunderbird-accounts-warning =
      let
        msg = "programs.thunderbird.accounts is ignored in standalone home-manager builds";
        warns = x: lib.any (lib.hasInfix msg) x.config.warnings;
      in
      expect "thunderbird warning [accounts set, accounts empty]" [ (warns progsOn) (warns progsOff) ] [ true false ];

    check-nh-home-timer = all [
      (expect "NAS myconfig.nh.enable" nasNhCfg.enable true)
      (expect "NAS programs.nh.enable" nasCfg.programs.nh.enable true)
      (expect "NAS programs.nh.clean.enable" nasCfg.programs.nh.clean.enable true)
      (expect "NAS systemd user timer nh-clean present" (nasCfg.systemd.user.timers ? nh-clean) true)
      (if nasFlakeDir == "" then "FAIL: flakeDir constant empty (control)" else "ok")
      (expect "NAS programs.nh.flake" nasCfg.programs.nh.flake "${nasCfg.home.homeDirectory}/${nasFlakeDir}")
      (expect "NAS nh clean extraArgs follow gcd/gcn" nasCfg.programs.nh.clean.extraArgs [ "--keep-since" nasNhCfg.gcd "--keep" nasNhCfg.gcn ])
    ];

    check-nh-no-duplicate-hm-timer-on-nixos = guard (
      let u = nixosNhOn.config.home-manager.users.krit;
      in all [
        (expect "NixOS system programs.nh.clean.enable (control: nh really on)" nixosNhOn.config.programs.nh.clean.enable true)
        (expect "integrated HM programs.nh.enable" u.programs.nh.enable false)
        (expect "integrated HM nh-clean user timer" (u.systemd.user.timers ? nh-clean) false)
      ]
    );

    check-sidra-theme-gating =
      let
        polarity = nasCfg.myconfig.constants.theme.polarity;
        on = sidraTheme (sidraTwin true true);
      in
      all [
        (if on == null then "FAIL: stylix on + customTheme on: custom-theme.json missing" else expect "theme json top-level keys" (builtins.attrNames on) [ polarity ])
        (expect "custom-theme.json [stylix on/customTheme off, stylix off/customTheme on, both off]"
          [ (sidraTheme (sidraTwin true false)) (sidraTheme (sidraTwin false true)) (sidraTheme (sidraTwin false false)) ]
          [ null null null ])
        (expect "sidra disabled: no custom-theme.json" (nasCfg.home.file ? ${sidraKey}) false)
      ];

    check-zen-stylix-profile-names = all [
      (expect "NAS zen off: profileNames (control)" (zenNames nasCfg) [ ])
      (expect "standalone home zen on: profileNames" (zenNames (zenForced homes."krit@template-host-minimal").config) [ "default" ])
      (expect "krit@nixos-laptop home build profileNames" (zenNames (zenForced homes."krit@nixos-laptop").config) [ "default" ])
      (expect "krit@nixos-desktop home build profileNames" (zenNames (zenForced homes."krit@nixos-desktop").config) [ "default" ])
      (guard (
        let n = zenForced flake.nixosConfigurations.template-host-minimal;
        in all [
          (expect "integrated NixOS HM profileNames" (zenNames n.config.home-manager.users.krit) [ "default" ])
          (expect "NixOS toplevel stylix.targets has zen-browser" (n.config.stylix.targets ? "zen-browser") false)
        ]
      ))
    ];

    check-nixos-openrouter-aliases-follow-wrappers = guard (
      let has = x: builtins.elem "cai-openrouter-opus" (aliasKeys x.config.home-manager.users.krit.programs);
      in expect "NixOS cai-openrouter-opus alias [wrappers on, off]" [ (has (nixosCc true)) (has (nixosCc false)) ] [ true false ]
    );
  };

in
{
  hostNames = builtins.attrNames homes;

  inherit homePrograms;

  check-host-instantiates = hostName: instantiates hostName homes.${hostName};

  check-catppuccin-home-mode =
    expect "NAS catppuccin enable/autoEnable"
      [ nasCfg.catppuccin.enable nasCfg.catppuccin.autoEnable ]
      [ true false ];

  check-pkgsstable-source =
    expect "pkgsStable source path" stableProbe.path (toString flake.inputs.nixpkgs-stable);

  check-pkgsstable-older-than-main =
    if lib.versionOlder stableProbe.version lib.version then "ok"
    else "FAIL: pkgsStable (${stableProbe.version}) is not older than nixpkgs (${lib.version})";

  check-substituters-match-nixos = guard (
    expect "NAS vs NixOS extra-substituters"
      nasCfg.nix.settings.extra-substituters
      flake.nixosConfigurations.template-host-minimal.config.nix.settings.extra-substituters
  );

  check-trusted-keys-match-nixos = guard (
    expect "NAS vs NixOS extra-trusted-public-keys"
      nasCfg.nix.settings.extra-trusted-public-keys
      flake.nixosConfigurations.template-host-minimal.config.nix.settings.extra-trusted-public-keys
  );

  check-nix-conf-rendered =
    if nasCfg.nix.settings.extra-substituters == [ ] then "FAIL: NAS extra-substituters empty"
    else expect "nix/nix.conf xdg.configFile enabled" (nasCfg.xdg.configFile."nix/nix.conf".enable or false) true;
}
