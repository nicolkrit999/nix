let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  nixosFile = flakeRoot + "/users/krit/nixos/services/ext-dotfiles-private.nix";
  darwinFile = flakeRoot + "/users/krit/darwin/services/ext-dotfiles-private.nix";

  loadData = file:
    let
      text = builtins.readFile file;
      afterLet = lib.concatStringsSep "\nlet\n" (builtins.tail (lib.splitString "\nlet\n" text));
      body = builtins.head (lib.splitString "\nin\n" afterLet);
    in
    import
      (builtins.toFile "ext-dotfiles-data.nix" ''
        { lib }:
        let
        ${body}
        in { inherit packageLeaves packagesPerHost extraMappingsPerHost syncBack; }
      '')
      { inherit lib; };

  nixosData = loadData nixosFile;
  darwinData = loadData darwinFile;

  nixosCfg = name: flake.nixosConfigurations.${name}.config;
  darwinCfg = flake.darwinConfigurations.Krits-MacBook-Pro.config;
  nasCfg = flake.homeConfigurations."krit@Nicol-NAS".config;

  hosts = {
    desktop = rec {
      data = nixosData;
      c = nixosCfg "nixos-desktop";
      hm = c.home-manager.users.krit.home;
      homeDir = "/home/krit";
      schoolPrefix = ".school-workspace/";
      kind = "nixos";
    };
    laptop = rec {
      data = nixosData;
      c = nixosCfg "nixos-laptop";
      hm = c.home-manager.users.krit.home;
      homeDir = "/home/krit";
      schoolPrefix = ".school-workspace/";
      kind = "nixos";
    };
    nas = rec {
      data = nixosData;
      c = nasCfg;
      hm = c.home;
      homeDir = "/home/krit";
      schoolPrefix = null;
    };
    mac = rec {
      data = darwinData;
      c = darwinCfg;
      hm = c.home-manager.users.krit.home;
      homeDir = "/Users/krit";
      schoolPrefix = "school-workspace/";
      kind = "darwin";
    };
  };

  ok = "ok";
  fail = msg: "FAIL: ${msg}";
  verdict = msgs: if msgs == [ ] then ok else fail (lib.concatStringsSep "; " msgs);
  eq = what: got: want:
    if got == want then ok
    else fail "${what} = ${builtins.toJSON got}, expected ${builtins.toJSON want}";

  hostname = h: h.c.myconfig.constants.hostname;
  enabledPackages = h: h.data.packagesPerHost.${hostname h} or [ ];
  leavesOf = h: lib.concatMap (p: h.data.packageLeaves.${p}) (enabledPackages h);
  extraOf = h: h.data.extraMappingsPerHost.${hostname h} or { };
  mappingsOf = h:
    lib.foldl' (acc: p: acc // lib.listToAttrs (map (l: { name = l; value = "${p}/${l}"; }) h.data.packageLeaves.${p}))
      { }
      (enabledPackages h) // extraOf h;
  expectedSyncBack = h: lib.filter (p: (mappingsOf h) ? ${p}) h.data.syncBack;

  duplicates = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);
  packageOverlap = data: hostPkgs:
    let
      leaves = lib.concatMap (p: map (l: { inherit p l; }) data.${p}) hostPkgs;
      names = map (x: x.l) leaves;
    in
    map (d: "${d} in ${lib.concatStringsSep "+" (map (x: x.p) (lib.filter (x: x.l == d) leaves))}") (duplicates names);
  intersect = a: b: lib.filter (x: builtins.elem x b) a;

  uniqueCheck = h:
    verdict (map (d: "leaf in two packages: ${d}") (duplicates (leavesOf h)));
  disjointCheck = h:
    verdict (map (k: "extraMappings key also a package leaf: ${k}") (intersect (builtins.attrNames (extraOf h)) (leavesOf h)));
  hostKnownCheck = h:
    if enabledPackages h == [ ] then fail "hostname ${hostname h} has no packagesPerHost entry (silent no-op)" else ok;
  packagesExistCheck = h:
    verdict (map (p: "package ${p} missing from packageLeaves") (lib.filter (p: !(h.data.packageLeaves ? ${p})) (enabledPackages h)));

  linkCheck = h:
    let
      files = h.hm.file;
      m = mappingsOf h;
      bad = lib.concatMap
        (k:
          if !(files ? ${k}) then [ "home.file lacks ${k}" ]
          else
            let want = "ln -s ${h.homeDir}/dotfiles-private/${m.${k}} $out"; in
            (lib.optional (files.${k}.source.buildCommand != want) "${k} links ${files.${k}.source.buildCommand}, expected ${want}")
            ++ (lib.optional (files.${k}.force != true) "${k} not force"))
        (builtins.attrNames m);
    in
    if m == { } then fail "no mappings at all" else verdict bad;

  syncBackCalls = h:
    lib.filter (l: lib.hasPrefix "sync_back " l) (lib.splitString "\n" h.hm.activation.syncBackDotfilesPrivate.data);
  syncBackCheck = h:
    eq "sync_back calls" (syncBackCalls h)
      (map (p: "sync_back ${lib.escapeShellArg p} ${lib.escapeShellArg (mappingsOf h).${p}}") (expectedSyncBack h));
  syncBackNonEmpty = h:
    if expectedSyncBack h == [ ] then fail "no syncBack path active on this host" else ok;

  syncBackKnownCheck = data:
    let leaves = lib.concatLists (builtins.attrValues data.packageLeaves);
    in verdict (map (p: "syncBack path ${p} is not a leaf of any package") (lib.filter (p: !(builtins.elem p leaves)) data.syncBack));

  keysKnownCheck = data: realHosts:
    verdict (
      map (k: "packagesPerHost key ${k} is not a real host") (lib.filter (k: !(builtins.elem k realHosts)) (builtins.attrNames data.packagesPerHost))
      ++ map (k: "extraMappingsPerHost key ${k} is not a real host") (lib.filter (k: !(builtins.elem k realHosts)) (builtins.attrNames data.extraMappingsPerHost))
    );

  unusedCheck = data: pkgsLists:
    let used = lib.unique (lib.concatLists pkgsLists);
    in verdict (map (p: "package ${p} defined but used by no host") (lib.filter (p: !(builtins.elem p used)) (builtins.attrNames data.packageLeaves)));

  schoolCheck = h:
    let
      keys = builtins.attrNames h.hm.file;
      school = lib.filter (k: lib.hasInfix "school-workspace" k) keys;
      bad = lib.filter (k: !(lib.hasPrefix h.schoolPrefix k)) school;
    in
    if school == [ ] then fail "no school-workspace link in home.file"
    else verdict (map (k: "wrong school-workspace prefix: ${k}") bad);

  launcher = "start-actual-mcp";
  launcherSource = "claude/common/binaries/start-actual-mcp";
  launcherKeys = m: lib.filter (k: m.${k} == launcherSource) (builtins.attrNames m);
  pathDirsOf = h:
    (if h.kind == "nixos" then lib.optional h.c.environment.localBinInPath "$HOME/.local/bin" else [ ])
    ++ h.hm.sessionPath;
  launcherMappingCheck = m:
    let keys = launcherKeys m;
    in
    if keys == [ ] then fail "no mapping with source ${launcherSource}"
    else if builtins.length keys > 1 then fail "several mappings for ${launcherSource}: ${builtins.toJSON keys}"
    else if baseNameOf (builtins.head keys) != launcher then fail "${builtins.head keys} does not end in ${launcher}"
    else ok;
  launcherPathCheck = m: pathDirs:
    let
      keys = launcherKeys m;
      onPath = map (lib.removePrefix "$HOME/") pathDirs;
      dir = dirOf (builtins.head keys);
    in
    if keys == [ ] then fail "no mapping with source ${launcherSource}"
    else if builtins.elem dir onPath then ok
    else fail "${launcher} is linked into ${dir}, not on PATH (PATH dirs: ${builtins.toJSON pathDirs})";
  binTwin = m: (removeAttrs m (launcherKeys m)) // { "bin/${launcher}" = launcherSource; };
  wrongSourceTwin = m: (removeAttrs m (launcherKeys m)) // { ".local/bin/${launcher}" = "claude/common/binaries/other"; };
  flagged = what: v: if lib.hasPrefix "FAIL: " v then ok else fail "control ${what} was not flagged (got ${v})";
  launcherChecks = name: h: {
    "check-${name}-launcher-mapping" = launcherMappingCheck (mappingsOf h);
    "check-${name}-launcher-on-path" = launcherPathCheck (mappingsOf h) (pathDirsOf h);
    "check-control-${name}-launcher-bin-dir" = flagged "bin/ twin" (launcherPathCheck (binTwin (mappingsOf h)) (pathDirsOf h));
    "check-control-${name}-launcher-path-lacks-dir" = flagged "PATH without the dir" (launcherPathCheck (mappingsOf h) [ ]);
    "check-control-${name}-launcher-wrong-source" = flagged "wrong source" (launcherMappingCheck (wrongSourceTwin (mappingsOf h)));
  };

  forbiddenClaudeLinks = [ ".claude/projects" ".claude/plans" ".claude/settings.json" ];
  noClaudeLinksCheck = files:
    verdict (map (k: "home.file still maps ${k}") (lib.filter (k: files ? ${k}) forbiddenClaudeLinks));

  encodeCwd = lib.replaceStrings [ "/" "." ] [ "-" "-" ];
  isDarwinHost = h: (h.kind or "nixos") == "darwin";
  sharedProjects = {
    nix = "nix";
    dotfiles-private = "dotfiles-private";
    dotfiles = "dotfiles";
    github-repos-personal-portainer-templates = "github-repos/personal/portainer-templates";
    momentary-gym-claude-skill = "momentary/gym-claude-skill";
  };
  nasProjectCwd = "/mnt/nicol-nas/webdav/owncloud/University";
  nasProjectName = "nicol-nas-webdav-owncloud-University";
  expectedMemoryLines = h:
    lib.mapAttrsToList (n: rel: "link_memory ${encodeCwd "${h.homeDir}/${rel}"} ${n}") sharedProjects
    ++ lib.optional (!isDarwinHost h) "link_memory ${encodeCwd nasProjectCwd} ${nasProjectName}";
  memoryLinesOf = text: lib.filter (l: lib.hasPrefix "link_memory " l) (lib.splitString "\n" text);
  memoryCheck = h: text:
    let
      got = memoryLinesOf text;
      want = expectedMemoryLines h;
      okPrefix = l:
        lib.hasPrefix "link_memory ${encodeCwd h.homeDir}-" l
        || (!isDarwinHost h && lib.hasPrefix "link_memory ${encodeCwd nasProjectCwd} " l);
    in
    verdict (
      map (l: "missing line: ${l}") (lib.filter (l: !(builtins.elem l got)) want)
      ++ map (l: "unexpected prefix on this platform: ${l}") (lib.filter (l: !(okPrefix l)) got)
      ++ lib.optional (!(lib.hasInfix "dir=\"${h.homeDir}/.claude/projects/$1\"" text)) "link_memory dir is not ${h.homeDir}/.claude/projects/$1"
      ++ lib.optional (!(lib.hasInfix "repo_root=\"${h.homeDir}/dotfiles-private\"" text)) "repo_root is not ${h.homeDir}/dotfiles-private"
    );
  settingsCheck = h: text:
    let
      src = "${h.homeDir}/dotfiles-private/claude/common/.claude/settings.json";
      dst = "${h.homeDir}/.claude/settings.json";
    in
    verdict (
      lib.optional (!(lib.hasInfix "src=\"${src}\"\n" text)) "src is not ${src}"
      ++ lib.optional (!(lib.hasInfix "dst=\"${dst}\"\n" text)) "dst is not ${dst}"
      ++ lib.optional (!(lib.hasInfix "ln -sfn \"$src\" \"$dst\"" text)) "no ln -sfn \"$src\" \"$dst\""
      ++ lib.optional (lib.hasInfix "/nix/store/" (lib.concatStringsSep "\n" (lib.filter (l: lib.hasPrefix "src=" l || lib.hasPrefix "dst=" l) (lib.splitString "\n" text)))) "src/dst route through /nix/store"
    );
  afterLinkGeneration = h: name:
    eq "${name} ordering" h.hm.activation.${name}.after [ "linkGeneration" ];
  claudeActivation = name: h: {
    "check-${name}-no-claude-home-file" = noClaudeLinksCheck h.hm.file;
    "check-${name}-memory-script" = memoryCheck h h.hm.activation.linkClaudeProjectMemory.data;
    "check-${name}-settings-script" = settingsCheck h h.hm.activation.linkClaudeSettings.data;
    "check-${name}-claude-activation-order" = verdict (lib.filter (r: r != ok) [
      (afterLinkGeneration h "linkClaudeProjectMemory")
      (afterLinkGeneration h "linkClaudeSettings")
    ]);
  };

  allPkgs = hs: map enabledPackages hs;
  nixosHosts = [ hosts.desktop hosts.laptop hosts.nas ];

  perHost = name: h: {
    "check-${name}-leaves-unique" = uniqueCheck h;
    "check-${name}-extra-disjoint" = disjointCheck h;
    "check-${name}-hostname-known" = hostKnownCheck h;
    "check-${name}-packages-exist" = packagesExistCheck h;
    "check-${name}-links" = linkCheck h;
    "check-${name}-syncback-calls" = syncBackCheck h;
  };

  fake = { a = [ "x" "y" ]; b = [ "y" "z" ]; };
in
perHost "desktop" hosts.desktop
// perHost "laptop" hosts.laptop
// perHost "nas" hosts.nas
// perHost "mac" hosts.mac
// claudeActivation "desktop" hosts.desktop
// claudeActivation "laptop" hosts.laptop
// claudeActivation "nas" hosts.nas
// claudeActivation "mac" hosts.mac
// launcherChecks "desktop" hosts.desktop
// launcherChecks "laptop" hosts.laptop
// launcherChecks "mac" hosts.mac
  // {
  "check-desktop-syncback-nonempty" = syncBackNonEmpty hosts.desktop;
  "check-laptop-syncback-nonempty" = syncBackNonEmpty hosts.laptop;
  "check-mac-syncback-nonempty" = syncBackNonEmpty hosts.mac;

  "check-nixos-syncback-known" = syncBackKnownCheck nixosData;
  "check-darwin-syncback-known" = syncBackKnownCheck darwinData;

  "check-nixos-host-keys-real" = keysKnownCheck nixosData (map hostname nixosHosts);
  "check-darwin-host-keys-real" = keysKnownCheck darwinData [ (hostname hosts.mac) ];

  "check-nixos-no-unused-package" = unusedCheck nixosData (allPkgs nixosHosts);
  "check-darwin-no-unused-package" = unusedCheck darwinData (allPkgs [ hosts.mac ]);

  "check-desktop-school-dot" = schoolCheck hosts.desktop;
  "check-laptop-school-dot" = schoolCheck hosts.laptop;
  "check-mac-school-nodot" = schoolCheck hosts.mac;
  "check-nas-no-school" = verdict (map (k: "unexpected ${k}") (lib.filter (k: lib.hasInfix "school-workspace" k) (builtins.attrNames hosts.nas.hm.file)));

  "check-control-claude-home-file-projects" =
    flagged "projects mapping" (noClaudeLinksCheck (hosts.desktop.hm.file // { ".claude/projects" = { }; }));
  "check-control-claude-home-file-settings" =
    flagged "settings.json mapping" (noClaudeLinksCheck (hosts.mac.hm.file // { ".claude/settings.json" = { }; }));
  "check-control-memory-wrong-platform-name" =
    flagged "linux encoded name on mac" (memoryCheck hosts.mac (lib.replaceStrings [ "-Users-krit-nix" ] [ "-home-krit-nix" ] hosts.mac.hm.activation.linkClaudeProjectMemory.data));
  "check-control-memory-missing-nas-project" =
    flagged "NAS project dropped on desktop" (memoryCheck hosts.desktop (lib.replaceStrings [ "-mnt-nicol-nas-webdav-owncloud-University" ] [ "-mnt-other" ] hosts.desktop.hm.activation.linkClaudeProjectMemory.data));
  "check-control-memory-nas-project-on-mac" =
    flagged "NAS project on mac" (memoryCheck hosts.mac (hosts.mac.hm.activation.linkClaudeProjectMemory.data + "\nlink_memory -mnt-nicol-nas-webdav-owncloud-University x"));
  "check-control-settings-store-dst" =
    flagged "settings dst in /nix/store" (settingsCheck hosts.desktop (lib.replaceStrings [ "dst=\"/home/krit/.claude" ] [ "dst=\"/nix/store/x-home/.claude" ] hosts.desktop.hm.activation.linkClaudeSettings.data));
  "check-control-settings-wrong-src" =
    flagged "settings src on wrong path" (settingsCheck hosts.laptop (lib.replaceStrings [ "common/.claude/settings.json" ] [ "mac/.claude/settings.json" ] hosts.laptop.hm.activation.linkClaudeSettings.data));

  "check-control-overlap-detected" = eq "overlap detector" (packageOverlap fake [ "a" "b" ]) [ "y in a+b" ];
  "check-control-overlap-clean" = eq "overlap detector on disjoint" (packageOverlap fake [ "a" ]) [ ];
  "check-control-typo-host-detected" =
    eq "typo host" (hostKnownCheck (hosts.desktop // { c = { myconfig.constants.hostname = "nixos-desktpo"; }; })) (fail "hostname nixos-desktpo has no packagesPerHost entry (silent no-op)");
}
