{ host, ciBuild ? "", ciDarwin ? "" }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  c = sys.config;
  twin = modules: (sys.extendModules { inherit modules; }).config;
  mk = lib.mkForce;

  workflowFile = override: name: if override != "" then override else "${flake.outPath}/.github/workflows/${name}";
  buildText = builtins.readFile (workflowFile ciBuild "build.yml");
  darwinText = builtins.readFile (workflowFile ciDarwin "build-darwin.yml");

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  count = x: xs: builtins.length (builtins.filter (y: y == x) xs);
  dups = xs: lib.unique (builtins.filter (x: count x xs > 1) xs);
  setDiff = what: a: b:
    let
      missing = builtins.filter (x: !(builtins.elem x b)) a;
      extra = builtins.filter (x: !(builtins.elem x a)) b;
    in
    (lib.optional (missing != [ ]) "${what}: only in module: ${builtins.toJSON missing}")
    ++ (lib.optional (extra != [ ]) "${what}: only in CI: ${builtins.toJSON extra}");

  trustProblems = cfg:
    let tu = cfg.nix.settings.trusted-users; in
    (lib.optional (count "@wheel" tu != 1) "@wheel appears ${toString (count "@wheel" tu)} times in ${builtins.toJSON tu}")
    ++ (lib.optional (count "root" tu != 1) "root appears ${toString (count "root" tu)} times in ${builtins.toJSON tu}")
    ++ (map (u: "unexpected trusted user ${u}") (builtins.filter (u: u != "root" && u != "@wheel") tu));

  platformProblems = cfg:
    let
      ep = cfg.nix.settings.extra-platforms or [ ];
      emu = cfg.boot.binfmt.emulatedSystems;
      binfmtDefault = lib.optional (emu != [ ]) "i686-linux";
    in
    (map (p: "duplicate extra-platform ${p}") (dups ep))
    ++ (map (p: "emulated system ${p} missing from extra-platforms") (builtins.filter (p: !(builtins.elem p ep)) emu))
    ++ (map (p: "extra-platform ${p} not provided by binfmt.emulatedSystems") (builtins.filter (p: !(builtins.elem p (emu ++ binfmtDefault))) ep));

  allSubs = cfg: (cfg.nix.settings.substituters or [ ]) ++ (cfg.nix.settings.extra-substituters or [ ]);
  allKeys = cfg: (cfg.nix.settings.trusted-public-keys or [ ]) ++ (cfg.nix.settings.extra-trusted-public-keys or [ ]);

  urlHost = url:
    let
      noScheme = lib.removePrefix "https://" (lib.removePrefix "http://" url);
      authority = lib.head (lib.splitString "/" noScheme);
    in
    lib.head (lib.splitString ":" (lib.head (lib.splitString "?" authority)));

  keyPrefix = cfg: url:
    let h = urlHost url; in
    if lib.hasPrefix cfg.myconfig.attic.serverUrl url then "${cfg.myconfig.attic.cacheName}:"
    else if h == "cache.nixos.org" || lib.hasSuffix ".cachix.org" h then "${h}-1:"
    else null;

  pairingProblems = cfg: subs: keys:
    lib.concatMap
      (u:
        let p = keyPrefix cfg u; in
        if p == null then [ "no pairing rule for substituter ${u}" ]
        else if builtins.any (k: lib.hasPrefix p k) keys then [ ]
        else [ "substituter ${u} has no trusted key starting with ${p}" ])
      subs;

  nixCacheProblems = cfg:
    (map (s: "niri cache still configured as substituter: ${s}") (builtins.filter (lib.hasInfix "niri") (allSubs cfg)))
    ++ (map (k: "niri cache key still trusted: ${builtins.head (lib.splitString ":" k)}") (builtins.filter (lib.hasInfix "niri") (allKeys cfg)))
    ++ (map (s: "duplicate substituter ${s}") (dups (allSubs cfg)))
    ++ (map (k: "duplicate trusted key ${builtins.head (lib.splitString ":" k)}") (dups (allKeys cfg)))
    ++ pairingProblems cfg (allSubs cfg) (allKeys cfg);

  modSubs = cfg: builtins.filter (u: !(lib.hasPrefix cfg.myconfig.attic.serverUrl u)) cfg.nix.settings.extra-substituters;
  modKeys = cfg: builtins.filter (k: k != cfg.myconfig.attic.publicKey) cfg.nix.settings.extra-trusted-public-keys;

  ciValues = key: text:
    lib.concatMap
      (l:
        let m = builtins.match "[ \t]*${key} = (.*)" l; in
        if m == null then [ ] else [ (builtins.filter (t: t != "") (lib.splitString " " (builtins.head m))) ])
      (lib.splitString "\n" text);

  ciDriftProblems = cfg: text:
    let
      subsRuns = ciValues "extra-substituters" text;
      keysRuns = ciValues "extra-trusted-public-keys" text;
    in
    (lib.optional (subsRuns == [ ]) "no extra-substituters line found")
    ++ (lib.optional (keysRuns == [ ]) "no extra-trusted-public-keys line found")
    ++ lib.concatMap (s: setDiff "extra-substituters" (modSubs cfg) s) subsRuns
    ++ lib.concatMap (k: setDiff "extra-trusted-public-keys" (modKeys cfg) k) keysRuns;

  darwinSubsetProblems = cfg: text:
    let
      subsRuns = ciValues "extra-substituters" text;
      keysRuns = ciValues "extra-trusted-public-keys" text;
    in
    (lib.optional (subsRuns == [ ]) "no extra-substituters line found")
    ++ (lib.optional (keysRuns == [ ]) "no extra-trusted-public-keys line found")
    ++ lib.concatMap (s: map (u: "darwin CI substituter not declared by the module: ${u}") (builtins.filter (u: !(builtins.elem u (modSubs cfg))) s)) subsRuns
    ++ lib.concatMap (k: map (_: "darwin CI key not declared by the module") (builtins.filter (x: !(builtins.elem x (modKeys cfg))) k)) keysRuns
    ++ lib.concatMap (s: lib.concatMap (k: pairingProblems cfg s k) keysRuns) subsRuns;

  polkitProblems = cfg:
    let t = cfg.security.polkit.extraConfig; in
    (map (a: "RealtimeKit clause missing: ${a}")
      (builtins.filter (a: !(lib.hasInfix a t)) [
        "org.freedesktop.RealtimeKit1.acquire-high-priority"
        "org.freedesktop.RealtimeKit1.acquire-real-time"
      ]))
    ++ (map (s: "forbidden polkit rule fragment ${s}")
      (builtins.filter (s: lib.hasInfix s t) [ "action.lookup(" "gpu-screen-recorder" "gsr-kms-server" "org.freedesktop.policykit.exec" ]));

  gsrNames = [ "gpu-screen-recorder" "gsr-kms-server" ];
  wrappersOffProblems = cfg:
    map (n: "wrapper ${n} present") (builtins.filter (n: cfg.security.wrappers ? ${n}) gsrNames);
  wrappersOnProblems = cfg:
    (lib.optional (!(cfg.security.wrappers ? gsr-kms-server)) "gsr-kms-server wrapper missing")
    ++ (lib.optional ((cfg.security.wrappers.gsr-kms-server.capabilities or null) != "cap_sys_admin+ep") "gsr-kms-server capabilities are ${builtins.toJSON (cfg.security.wrappers.gsr-kms-server.capabilities or null)}")
    ++ (lib.optional (cfg.security.wrappers ? gpu-screen-recorder) "gpu-screen-recorder main binary is wrapped");

  sshProblems = cfg:
    let fw = cfg.networking.firewall; in
    (lib.optional (!cfg.services.openssh.enable) "services.openssh.enable is false")
    ++ (lib.optional cfg.services.openssh.openFirewall "services.openssh.openFirewall is true")
    ++ (lib.optional (builtins.elem 22 fw.allowedTCPPorts) "22 in allowedTCPPorts")
    ++ (lib.optional (builtins.any (r: r.from <= 22 && 22 <= r.to) fw.allowedTCPPortRanges) "22 inside an allowedTCPPortRanges entry")
    ++ (lib.optional (!(builtins.elem "tailscale0" fw.trustedInterfaces)) "tailscale0 not in trustedInterfaces");

  crashProblems = cfg:
    let rm = cfg.boot.crashDump.reservedMemory; in
    (lib.optional (!cfg.boot.crashDump.enable) "boot.crashDump.enable is false")
    ++ (lib.optional (rm != "512M") "reservedMemory is ${builtins.toJSON rm}")
    ++ (lib.optional (!(builtins.elem "crashkernel=${rm}" cfg.boot.kernelParams)) "crashkernel=${rm} not in kernelParams");

  shellOn = shell: [{
    myconfig.programs.hyprland.enable = mk true;
    myconfig.programs.${shell} = {
      enable = mk true;
      enableOnHyprland = mk true;
    };
  }];
  noctaliaOn = twin (shellOn "noctalia");
  caelestiaOn = twin (shellOn "caelestia");

  victimSub = lib.head (builtins.filter (lib.hasSuffix ".cachix.org") (modSubs c));
  victimKey = lib.head (modKeys c);

  checks = {
    "trust: trusted-users has @wheel and root exactly once, nothing else" = failIf (trustProblems c);
    "platforms: extra-platforms match binfmt.emulatedSystems, no duplicates" = failIf (platformProblems c);
    "cache: no niri cache, no duplicates, every substituter has a key" = failIf (nixCacheProblems c);
    "drift: build.yml substituters and keys equal the module's set" = failIf (ciDriftProblems c buildText);
    "drift: build-darwin.yml substituters and keys are a paired subset of the module's set" = failIf (darwinSubsetProblems c darwinText);
    "polkit: RealtimeKit clause present, no program-path substring or exec clause" = failIf (polkitProblems c);
    "wrappers: shells off, no gpu-screen-recorder or gsr-kms-server wrapper" = failIf (wrappersOffProblems c);
    "wrappers: noctalia on, gsr-kms-server has cap_sys_admin+ep and the main binary is not wrapped" = failIf (wrappersOnProblems noctaliaOn);
    "wrappers: caelestia on, gsr-kms-server has cap_sys_admin+ep and the main binary is not wrapped" = failIf (wrappersOnProblems caelestiaOn);
    "ssh: enabled, firewall not opened, 22 closed, tailscale0 trusted" = failIf (sshProblems c);
    "crashdump: enabled, 512M reserved, crashkernel param present" = failIf (crashProblems c);

    "control(trust): duplicate root is detected" =
      detects "duplicate root" (trustProblems (twin [{ nix.settings.trusted-users = [ "root" ]; }]));
    "control(trust): extra trusted user is detected" =
      detects "extra user" (trustProblems (twin [{ nix.settings.trusted-users = [ "nobody" ]; }]));
    "control(platforms): stray extra-platform is detected" =
      detects "stray platform" (platformProblems (twin [{ nix.settings.extra-platforms = [ "riscv64-linux" ]; }]));
    "control(platforms): duplicate extra-platform is detected" =
      detects "duplicate platform" (platformProblems (twin [{ nix.settings.extra-platforms = mk [ "riscv64-linux" "riscv64-linux" ]; boot.binfmt.emulatedSystems = mk [ "riscv64-linux" ]; }]));
    "control(cache): niri substituter and key are detected" =
      detects "niri cache" (nixCacheProblems (twin [{
        nix.settings.extra-substituters = [ "https://niri.cachix.org" ];
        nix.settings.extra-trusted-public-keys = [ "niri.cachix.org-1:placeholder" ];
      }]));
    "control(cache): substituter without key is detected" =
      detects "unpaired substituter" (nixCacheProblems (twin [{ nix.settings.extra-substituters = [ "https://unpaired.cachix.org" ]; }]));
    "control(drift): CI missing a module substituter is detected" =
      detects "substituter swapped" (ciDriftProblems c (builtins.replaceStrings [ victimSub ] [ "https://example.invalid" ] buildText));
    "control(drift): CI with a different key is detected" =
      detects "key swapped" (ciDriftProblems c (builtins.replaceStrings [ victimKey ] [ "example.invalid-1:x" ] buildText));
    "control(drift): text without the CI lines is detected" =
      detects "no lines" (ciDriftProblems c "nothing here\n");
    "control(drift): darwin CI with a foreign substituter is detected" =
      detects "foreign substituter" (darwinSubsetProblems c (builtins.replaceStrings [ victimSub ] [ "https://example.invalid" ] darwinText + "\n  extra-substituters = https://example.invalid\n  extra-trusted-public-keys = example.invalid-1:x\n"));
    "control(polkit): gpu-screen-recorder substring rule is detected" =
      detects "gsr polkit rule" (polkitProblems (twin [{
        security.polkit.extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.policykit.exec" && action.lookup("program").indexOf("gpu-screen-recorder") >= 0) { return polkit.Result.YES; }
          });
        '';
      }]));
    "control(polkit): missing RealtimeKit clause is detected" =
      detects "no rtkit clause" (polkitProblems (twin [{ security.polkit.extraConfig = mk ""; }]));
    "control(wrappers): enabled recorder is flagged by the shells-off check" =
      detects "gsr wrapper" (wrappersOffProblems noctaliaOn);
    "control(wrappers): main-binary wrapper is detected" =
      detects "main wrapper" (wrappersOnProblems (twin (shellOn "noctalia" ++ [{
        security.wrappers.gpu-screen-recorder = { owner = "root"; group = "root"; source = "/dev/null"; capabilities = "cap_sys_admin+ep"; };
      }])));
    "control(wrappers): shells off lacks the wrapper the on-check requires" =
      detects "wrapper missing" (wrappersOnProblems c);
    "control(ssh): openFirewall is detected" =
      detects "openFirewall" (sshProblems (twin [{ services.openssh.openFirewall = mk true; }]));
    "control(ssh): port 22 in allowedTCPPorts is detected" =
      detects "port 22" (sshProblems (twin [{ networking.firewall.allowedTCPPorts = [ 22 ]; }]));
    "control(ssh): untrusted tailscale0 is detected" =
      detects "tailscale0" (sshProblems (twin [{ networking.firewall.trustedInterfaces = mk [ ]; }]));
    "control(ssh): disabled sshd is detected" =
      detects "sshd off" (sshProblems (twin [{ services.openssh.enable = mk false; }]));
    "control(crashdump): disabled crashDump is detected" =
      detects "crashDump off" (crashProblems (twin [{ boot.crashDump.enable = mk false; }]));
    "control(crashdump): other reservation is detected" =
      detects "128M" (crashProblems (twin [{ boot.crashDump.reservedMemory = mk "128M"; }]));
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
