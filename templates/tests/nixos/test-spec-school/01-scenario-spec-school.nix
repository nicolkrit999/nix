let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  base = flake.nixosConfigurations.${host}.config;
  spec = base.specialisation.school.configuration;
  c = spec.config or spec;
  hm = c.home-manager.users.krit;
  baseHm = base.home-manager.users.krit;
  home = hm.home.homeDirectory;
  mountPoint = "${home}/.school-workspace/opencloud";

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  data = s: s.data or s;
  sshOf = h: n: data (h.programs.ssh.settings.${n} or { });

  pkgByName = n: lib.findFirst (p: (p.name or "") == n) null hm.home.packages;
  scriptText = n: let p = pkgByName n; in if p == null then "" else p.text;
  scriptNames = [
    "tkgate-school"
    "sqldeveloper-school"
    "school-distrobox-setup"
    "school-distrobox-check"
    "school-distrobox-clear"
    "brave-school"
    "vscode-school"
    "idea-school"
  ];

  monitors = lib.filter (m: m.output != "" && !(m ? mirror) && (m.mode or "") != "disable") c.myconfig.programs.hyprland.monitors;
  scales = lib.unique (map (m: m.scale) monitors);
  scale = lib.head scales;
  scaleStr = toString scale;

  uiScaleOf = text:
    let m = builtins.match ".*uiScale=([0-9.]+).*" text;
    in if m == null then null else builtins.fromJSON (lib.head m);

  spaces = c.myconfig.krit.services.nas.opencloud-mount.spaces;
  fsName = s: "${mountPoint}/${s.path}";
  schoolFs = lib.filterAttrs (n: _: lib.hasPrefix "${mountPoint}/" n) c.fileSystems;
  optsOf = s: (c.fileSystems.${fsName s} or { options = [ ]; }).options;
  davfsRequired = [ "noauto" "nofail" "x-systemd.automount" "_netdev" ];
  userName = c.myconfig.constants.user;
  optEquals = key: val: opts: lib.elem "${key}=${val}" opts;
  badFs = pred: map (s: s.path) (lib.filter (s: !(pred s)) spaces);

  unit = c.systemd.services.tailscale-school-exit-node-off or null;
  unitDeps = if unit == null then [ ] else unit.after ++ unit.wants;
  serviceExists = u: c.systemd.services ? ${lib.removeSuffix ".service" u};

  gitSet = hm.programs.git.settings;
  signers = hm.home.file.".ssh/allowed_signers";
  signerFields = lib.splitString " " (lib.head (lib.splitString "\n" (lib.trim signers.text)));
  idFile = c.sops.secrets.school_ssh_key.path;

  workspacesOf = line: map lib.head (builtins.filter (m: m != null) (map (builtins.match "\\[workspace ([0-9]+).*") [ line ]));
  execWs = lib.concatMap workspacesOf c.myconfig.programs.hyprland.execOnce;
  declaredWs = map (m: m.workspace) c.myconfig.programs.hyprland.monitorWorkspaces;

  setup = scriptText "school-distrobox-setup";
  clear = scriptText "school-distrobox-clear";
  checkQuoted = builtins.length (lib.filter builtins.isList (builtins.split "bash -c '[^'\n]*' &>/dev/null" setup));

  sshHosts = [ "github.com" "gitlab.com" "gitlab-edu.supsi.ch" ];
  sshBad = pred: lib.filter (h: !(pred (sshOf hm h))) sshHosts;

  checks = [
    [ "specialisation.school evaluates for ${host}" (chk (base.specialisation ? school && c.system.nixos.tags == [ "school" ]) "specialisation.school missing or tags differ") ]
    [ "constants.shell == bash" (chk (c.myconfig.constants.shell == "bash") "shell is ${c.myconfig.constants.shell}") ]
    [ "myconfig.services.tailscale.enable" (chk c.myconfig.services.tailscale.enable "tailscale not forced on") ]
    [ "systemd.services has tailscale-autoconnect" (chk (c.systemd.services ? tailscale-autoconnect) "tailscale-autoconnect service absent") ]
    [ "exit-node-off wantedBy multi-user.target" (chk (unit != null && unit.wantedBy == [ "multi-user.target" ]) "unit missing or wantedBy differs") ]
    [ "exit-node-off after/wants units exist" (chk (unitDeps != [ ] && lib.all serviceExists unitDeps) "unknown units: ${toString (lib.filter (u: !serviceExists u) unitDeps)}") ]
    [ "exit-node-off stays After and Wants tailscale-autoconnect" (chk (unit != null && lib.elem "tailscale-autoconnect.service" unit.after && lib.elem "tailscale-autoconnect.service" unit.wants) "ordering on tailscale-autoconnect lost") ]
    [ "exit-node-off is non-blocking (Type=exec)" (chk (unit != null && (unit.serviceConfig.Type or "") == "exec") "Type is ${if unit == null then "missing" else unit.serviceConfig.Type or "unset"}") ]
    [ "exit-node-off retries tailscale set --exit-node= in a bounded timeout loop" (chk (unit != null && lib.hasInfix "seq 1 " unit.script && lib.hasInfix "timeout " unit.script && lib.hasInfix "tailscale set --exit-node= && exit 0" unit.script && lib.hasInfix "exit 1" unit.script && !(lib.hasInfix "BackendState" unit.script)) "script lacks bounded retry of the set, or still waits on BackendState") ]
    [ "exit-node-off has tailscale on its path" (chk (unit != null && lib.any (p: lib.hasPrefix "tailscale" (p.name or "")) unit.path) "tailscale package missing from unit path") ]

    [ "ssh enableDefaultConfig is off" (chk (hm.programs.ssh.enableDefaultConfig == false) "default ssh config re-enabled") ]
    [ "ssh IdentityFile is the sops school key for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentityFile or "") == idFile) == [ ]) "wrong IdentityFile for: ${toString (sshBad (s: (s.IdentityFile or "") == idFile))}") ]
    [ "ssh IdentitiesOnly == yes for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentitiesOnly or "") == "yes") == [ ]) "IdentitiesOnly not yes for: ${toString (sshBad (s: (s.IdentitiesOnly or "") == "yes"))}") ]
    [ "school github identity differs from the base host identity" (chk (sshOf baseHm "github.com" ? IdentityFile && (sshOf baseHm "github.com").IdentityFile != (sshOf hm "github.com").IdentityFile) "base and school share the github IdentityFile (or base has none)") ]

    [ "git user.email is school-specific and not the base email" (chk (gitSet.user.email != baseHm.programs.git.settings.user.email && gitSet.user.email != "") "school email equals base email") ]
    [ "git gpg.format == ssh and commit signing on" (chk (gitSet.gpg.format == "ssh" && hm.programs.git.signing.signByDefault && (gitSet.commit.gpgSign or false)) "ssh signing not fully enabled") ]
    [ "git signing key is the sops school key" (chk (hm.programs.git.signing.key == idFile && gitSet.user.signingkey == idFile) "signing key differs from ${idFile}") ]
    [ "allowedSignersFile == path of home.file allowed_signers" (chk (gitSet.gpg.ssh.allowedSignersFile == "${home}/${signers.target}") "${gitSet.gpg.ssh.allowedSignersFile} vs ${home}/${signers.target}") ]
    [ "allowed_signers principal == git user.email, ed25519 key" (chk (lib.length signerFields >= 3 && lib.elemAt signerFields 0 == gitSet.user.email && lib.elemAt signerFields 1 == "ssh-ed25519") "signers line does not match git identity") ]

    [ "opencloud spaces are non-empty" (chk (spaces != [ ]) "no spaces to mount") ]
    [ "one school davfs fileSystem per space, davfs type, device == url" (chk (lib.length (lib.attrNames schoolFs) == lib.length spaces && badFs (s: (c.fileSystems.${fsName s} or { }).fsType or "" == "davfs" && c.fileSystems.${fsName s}.device == s.url) == [ ]) "mismatch (fs entries ${toString (lib.length (lib.attrNames schoolFs))} vs spaces ${toString (lib.length spaces)}; bad: ${toString (badFs (s: (c.fileSystems.${fsName s} or { }).fsType or "" == "davfs"))})") ]
    [ "davfs options noauto, nofail, x-systemd.automount, _netdev" (chk (spaces != [ ] && badFs (s: lib.all (o: lib.elem o (optsOf s)) davfsRequired) == [ ]) "missing options for: ${toString (badFs (s: lib.all (o: lib.elem o (optsOf s)) davfsRequired))}") ]
    [ "davfs uid= option equals constants.user" (chk (spaces != [ ] && badFs (s: optEquals "uid" userName (optsOf s)) == [ ]) "uid= is not ${userName} for: ${toString (badFs (s: optEquals "uid" userName (optsOf s)))}; options: ${toString (optsOf (lib.head spaces))}") ]
    [ "davfs gid= option equals the user's primary group name" (chk (spaces != [ ] && badFs (s: optEquals "gid" c.users.users.${userName}.group (optsOf s)) == [ ]) "gid= is not ${c.users.users.${userName}.group} for: ${toString (badFs (s: optEquals "gid" c.users.users.${userName}.group (optsOf s)))}") ]
    [ "davfs2 enabled, secrets file linked, krit in davfs2 group" (chk (c.services.davfs2.enable && c.environment.etc ? "davfs2/secrets" && lib.elem "davfs2" c.users.users.krit.extraGroups) "davfs2 wiring incomplete") ]
    [ "no opencloud space path is exactly University" (chk (!(lib.any (s: s.path == "University") spaces)) "a space path collides with the University tmpfiles directory") ]

    [ "sqldeveloper uiScale == hyprland monitor scale, exact render" (chk (lib.length scales == 1 && lib.hasInfix "-Dsun.java2d.uiScale=${scaleStr}\"" (scriptText "sqldeveloper-school")) "monitor scales ${toString scales}; script uiScale ${toString (uiScaleOf (scriptText "sqldeveloper-school"))}") ]
    [ "sqldeveloper uiScale parses to the monitor scale as a float" (chk (lib.length scales == 1 && uiScaleOf (scriptText "sqldeveloper-school") == scale) "parsed ${toString (uiScaleOf (scriptText "sqldeveloper-school"))} vs ${toString scale}") ]
    [ "control: uiScale parser rejects a different scale" (chk (uiScaleOf "-Dsun.java2d.uiScale=${toString (scale + 0.1)}\"" != scale) "parser matches any scale") ]
    [ "tkgate Xft.dpi == floor(96 * monitor scale)" (chk (lib.hasInfix "Xft.dpi: ${toString (builtins.floor (96 * scale))}\"" (scriptText "tkgate-school")) "dpi mismatch for scale ${scaleStr}") ]

    [ "all eight school scripts are present and non-empty" (chk (lib.all (n: scriptText n != "") scriptNames) "missing: ${toString (lib.filter (n: scriptText n == "") scriptNames)}") ]
    [ "setup script creates school-ubuntu and school-arch" (chk (lib.hasInfix "--name \"school-ubuntu\"" setup && lib.hasInfix "--name \"school-arch\"" setup) "container names missing in setup") ]
    [ "clear script references both containers" (chk (lib.hasInfix "\"school-ubuntu\"" clear && lib.hasInfix "\"school-arch\"" clear) "container names missing in clear") ]
    [ "tkgate and sqldeveloper launchers enter the matching containers" (chk (lib.hasInfix "enter school-ubuntu" (scriptText "tkgate-school") && lib.hasInfix "enter school-arch" (scriptText "sqldeveloper-school")) "launcher container differs from setup") ]
    [ "every app check is single-quote-safe in the setup script" (chk (checkQuoted == 2) "found ${toString checkQuoted} well-quoted check invocations, expected 2") ]

    [ "hyprland execOnce workspaces are declared in monitorWorkspaces" (chk (execWs != [ ] && lib.all (w: lib.elem w declaredWs) execWs) "undeclared workspaces: ${toString (lib.filter (w: !(lib.elem w declaredWs)) execWs)}") ]
  ];

  startupDrvs = lib.filter (d: lib.hasSuffix "-school-distrobox-startup-check.drv" d) (builtins.attrNames (builtins.getContext hm.programs.bash.initExtra));
  deepDrvs = lib.filter (d: lib.hasSuffix "-school-distrobox-deep-check.drv" d) (builtins.attrNames (builtins.getContext (scriptText "school-distrobox-check")));
in
{
  report = lib.concatMapStringsSep "\n" (e: "${lib.elemAt e 0}\t${lib.elemAt e 1}") checks + "\n";
  scripts = builtins.toJSON (lib.genAttrs scriptNames scriptText);
  drvs = builtins.toJSON { startup = startupDrvs; deep = deepDrvs; };
}
