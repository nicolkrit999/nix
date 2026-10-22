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
  signerLines = lib.splitString "\n" (lib.trim signers.text);
  baseSignerLines = lib.splitString "\n" (lib.trim baseHm.home.file.".ssh/allowed_signers".text);
  principalOf = l: lib.head (lib.splitString " " l);

  entries = hm.xdg.desktopEntries;
  pwaNames = lib.filter (lib.hasPrefix "school-pwa-") (lib.attrNames entries);
  pwaOk = e: (e.mimeType or null) == null && (e.categories or null) == [ "Education" ];
  pwaBad = pred: lib.filter (n: !(pred entries.${n})) pwaNames;
  onedrive = hm.systemd.user.services.school-onedrive-mount;
  onedriveUnit = onedrive.Unit;
  createDirs = hm.home.activation.createSchoolDirs.data;
  anyHas = needle: lib.any (lib.hasInfix needle);

  workspacesOf = line: map lib.head (builtins.filter (m: m != null) (map (builtins.match "\\[workspace ([0-9]+).*") [ line ]));
  execWs = lib.concatMap workspacesOf c.myconfig.programs.hyprland.execOnce;
  declaredWs = map (m: m.workspace) c.myconfig.programs.hyprland.monitorWorkspaces;

  setup = scriptText "school-distrobox-setup";
  clear = scriptText "school-distrobox-clear";
  checkQuoted = builtins.length (lib.filter builtins.isList (builtins.split "bash -c '[^'\n]*' &>/dev/null" setup));

  sshHosts = [ "github.com" "gitlab.com" "gitlab-edu.supsi.ch" ];
  sshBad = pred: lib.filter (h: !(pred (sshOf hm h))) sshHosts;

  isLaptop = c.myconfig.constants.hostname == "nixos-laptop";

  printingProbe = cfg: names: lib.concatLists [
    (lib.optional (cfg.services.printing.enable or false) "cups")
    (lib.optional (cfg.environment.etc ? ${names.etc}) "etc")
    (lib.optional (cfg.systemd.services ? ${names.service}) "service")
    (lib.optional (cfg.sops.secrets ? ${names.secret}) "secret")
  ];
  printingNames = { etc = "samba/smb.conf"; service = "supsi-printer-setup"; secret = "school_supsi_password"; };
  knownNames = { etc = "davfs2/secrets"; service = "tailscaled-autoconnect"; secret = "school_ssh_key"; };

  printingChecks =
    [
      [ "control: myconfig.constants.hostname equals the evaluated host, so the laptop gate cannot misclassify a host" (chk (c.myconfig.constants.hostname == host && isLaptop == (host == "nixos-laptop")) "constants.hostname is ${c.myconfig.constants.hostname}, evaluated host is ${host}") ]
      [ "control: the printing probe reports etc, service and secret names that exist in the spec (probe bites)" (chk ((c.services.printing ? enable) && lib.subtractLists [ "cups" ] (printingProbe c knownNames) == [ "etc" "service" "secret" ]) "probe misses names that exist: ${toString (printingProbe c knownNames)}") ]
    ]
    ++ lib.optionals isLaptop [
      [ "SUPSI printing: cups on, smb.conf has SMB2" (chk (c.services.printing.enable && lib.hasInfix "client min protocol = SMB2" c.environment.etc."samba/smb.conf".text) "printing off or smb.conf lacks SMB2") ]
      [ "SUPSI printing: oneshot after cups, ExecStart is a store script without embedded credentials" (chk (c.services.printing.enable && (c.systemd.services ? supsi-printer-setup) && c.systemd.services.supsi-printer-setup.serviceConfig.Type == "oneshot" && lib.elem "cups.service" c.systemd.services.supsi-printer-setup.after && lib.hasPrefix "/nix/store/" (toString c.systemd.services.supsi-printer-setup.serviceConfig.ExecStart) && !(lib.hasInfix "smb://" (toString c.systemd.services.supsi-printer-setup.serviceConfig.ExecStart))) "printing service missing, not a oneshot after cups, or ExecStart not a plain store script") ]
      [ "SUPSI printing: smb.conf has client min protocol = SMB2, password secret is root 0400 and school-only" (chk (lib.hasInfix "client min protocol = SMB2" c.environment.etc."samba/smb.conf".text && (c.sops.secrets.school_supsi_password.mode == "0400" && c.sops.secrets.school_supsi_password.owner == "root") && !(base.sops.secrets ? school_supsi_password) && !(base.systemd.services ? supsi-printer-setup)) "smb.conf lacks SMB2, secret mode/owner differs, or the printing wiring leaks into the base config") ]
    ]
    ++ lib.optionals (!isLaptop) [
      [ "SUPSI printing is laptop-only: the spec has no cups, smb.conf, supsi-printer-setup or school_supsi_password, and the base has no school printing service or secret" (chk (printingProbe c printingNames == [ ] && !(base.systemd.services ? supsi-printer-setup) && !(base.sops.secrets ? school_supsi_password)) "printing wiring present on a non-laptop host: ${toString (printingProbe c printingNames)}") ]
    ];

  checks = [
    [ "specialisation.school evaluates for ${host}" (chk (base.specialisation ? school && c.system.nixos.tags == [ "school" ]) "specialisation.school missing or tags differ") ]
    [ "constants.shell == bash" (chk (c.myconfig.constants.shell == "bash") "shell is ${c.myconfig.constants.shell}") ]
    [ "myconfig.services.tailscale.enable" (chk c.myconfig.services.tailscale.enable "tailscale not forced on") ]
    [ "systemd.services has upstream tailscaled-autoconnect, not the removed tailscale-autoconnect" (chk (c.systemd.services ? tailscaled-autoconnect && !(c.systemd.services ? tailscale-autoconnect)) "tailscaled-autoconnect absent or removed tailscale-autoconnect is back") ]
    [ "exit-node-off wantedBy multi-user.target" (chk (unit != null && unit.wantedBy == [ "multi-user.target" ]) "unit missing or wantedBy differs") ]
    [ "exit-node-off after/wants units exist" (chk (unitDeps != [ ] && lib.all serviceExists unitDeps) "unknown units: ${toString (lib.filter (u: !serviceExists u) unitDeps)}") ]
    [ "exit-node-off After tailscaled, not the removed tailscale-autoconnect" (chk (unit != null && lib.elem "tailscaled.service" unit.after && !(lib.elem "tailscale-autoconnect.service" unitDeps)) "not After tailscaled.service or still references tailscale-autoconnect.service") ]
    [ "exit-node-off is non-blocking (Type=exec)" (chk (unit != null && (unit.serviceConfig.Type or "") == "exec") "Type is ${if unit == null then "missing" else unit.serviceConfig.Type or "unset"}") ]
    [ "exit-node-off retries tailscale set --exit-node= in a bounded timeout loop" (chk (unit != null && lib.hasInfix "seq 1 " unit.script && lib.hasInfix "timeout " unit.script && lib.hasInfix "tailscale set --exit-node= && exit 0" unit.script && lib.hasInfix "exit 1" unit.script && !(lib.hasInfix "BackendState" unit.script)) "script lacks bounded retry of the set, or still waits on BackendState") ]
    [ "exit-node-off has tailscale on its path" (chk (unit != null && lib.any (p: lib.hasPrefix "tailscale" (p.name or "")) unit.path) "tailscale package missing from unit path") ]

    [ "ssh enableDefaultConfig is off" (chk (hm.programs.ssh.enableDefaultConfig == false) "default ssh config re-enabled") ]
    [ "ssh IdentityFile is the sops school key for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentityFile or "") == idFile) == [ ]) "wrong IdentityFile for: ${toString (sshBad (s: (s.IdentityFile or "") == idFile))}") ]
    [ "ssh IdentitiesOnly == yes for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentitiesOnly or "") == "yes") == [ ]) "IdentitiesOnly not yes for: ${toString (sshBad (s: (s.IdentitiesOnly or "") == "yes"))}") ]
    [ "school github identity differs from the base host identity" (chk (sshOf baseHm "github.com" ? IdentityFile && (sshOf baseHm "github.com").IdentityFile != (sshOf hm "github.com").IdentityFile) "base and school share the github IdentityFile (or base has none)") ]

    [ "git user.email is school-specific and not the base email" (chk (gitSet.user.email != baseHm.programs.git.settings.user.email && gitSet.user.email != "") "school email equals base email") ]
    [ "git gpg.format == ssh and commit signing on" (chk (gitSet.gpg.format == "ssh" && hm.programs.git.signing.signByDefault && (gitSet.commit.gpgSign or false)) "ssh signing not fully enabled") ]
    [ "git signByDefault also signs tags" (chk ((hm.programs.git.iniContent.tag.gpgSign or false) == true) "tag.gpgSign is not true") ]
    [ "git signing key is user.signingKey == sops school key" (chk ((gitSet.user.signingKey or "") == idFile) "user.signingKey is '${gitSet.user.signingKey or "unset"}', expected ${idFile}") ]
    [ "no lowercase user.signingkey and no signing.key (single source: git-ssh-signing)" (chk (!(gitSet.user ? signingkey) && hm.programs.git.signing.key == null) "lowercase signingkey or signing.key is set again") ]
    [ "git-ssh-signing options carry the school key and school identity" (chk (c.myconfig.krit.system.git-ssh-signing.signingKey == idFile && c.myconfig.krit.system.git-ssh-signing.allowedSignersEmail == gitSet.user.email && c.myconfig.krit.system.git-ssh-signing.allowedSignersEmail != base.myconfig.krit.system.git-ssh-signing.allowedSignersEmail) "option values differ from the school identity") ]
    [ "allowedSignersFile == path of home.file allowed_signers" (chk (gitSet.gpg.ssh.allowedSignersFile == "${home}/${signers.target}") "${gitSet.gpg.ssh.allowedSignersFile} vs ${home}/${signers.target}") ]
    [ "allowed_signers first line == git user.email, ed25519 key" (chk (lib.length signerFields >= 3 && lib.elemAt signerFields 0 == gitSet.user.email && lib.elemAt signerFields 1 == "ssh-ed25519") "signers line does not match git identity") ]
    [ "allowed_signers has exactly two lines: school first, then the base (personal) line" (chk (lib.length signerLines == 2 && lib.length baseSignerLines == 1 && lib.elemAt signerLines 1 == lib.head baseSignerLines && principalOf (lib.elemAt signerLines 1) != gitSet.user.email) "lines: ${toString (lib.length signerLines)}; base lines: ${toString (lib.length baseSignerLines)}") ]
    [ "control: base allowed_signers does not name the school principal" (chk (!(lib.any (l: principalOf l == gitSet.user.email) baseSignerLines)) "base signers already contain the school principal") ]

    [ "school secrets are declared inside the specialisation, ssh pub next to the key" (chk (c.sops.secrets ? school_ssh_key && c.sops.secrets ? school_ssh_pub && c.sops.secrets.school_ssh_pub.path == "${idFile}.pub") "school_ssh_key/school_ssh_pub missing in the spec or pub path differs") ]
    [ "school secrets are absent from the base config (control)" (chk (!(base.sops.secrets ? school_ssh_key) && !(base.sops.secrets ? school_ssh_pub)) "base config declares the school secrets") ]

    [ "NetworkManager VPN plugins openvpn and openconnect are registered in the spec" (chk (c.environment.etc ? "NetworkManager/VPN/nm-openvpn-service.name" && c.environment.etc ? "NetworkManager/VPN/nm-openconnect-service.name") "nm-openvpn/nm-openconnect service.name missing from environment.etc") ]
    [ "control: an unrequested NM VPN plugin is not registered (etc probe bites)" (chk (!(c.environment.etc ? "NetworkManager/VPN/nm-nonexistent-service.name")) "etc probe accepts any name") ]
  ] ++ printingChecks ++ [
    [ "wireshark enabled in the spec and the user is in the wireshark group" (chk (c.programs.wireshark.enable && lib.elem "wireshark" c.users.users.${userName}.extraGroups) "wireshark or group membership missing") ]

    [ "school PWA entries exist, have no mimeType and are in category Education" (chk (pwaNames != [ ] && pwaBad pwaOk == [ ]) "bad PWA entries: ${toString (pwaBad pwaOk)} of ${toString pwaNames}") ]
    [ "control: PWA predicate rejects an entry with a mimeType or another category" (chk (pwaOk entries.${lib.head pwaNames} && !(pwaOk (entries.${lib.head pwaNames} // { mimeType = [ "x-scheme-handler/https" ]; })) && !(pwaOk (entries.${lib.head pwaNames} // { categories = [ "Network" "WebBrowser" ]; }))) "PWA predicate accepts a mimeType or a non-Education category") ]

    [ "OneDrive user unit has StartLimit settings and no network-online.target ordering" (chk ((onedriveUnit ? StartLimitIntervalSec) && (onedriveUnit ? StartLimitBurst) && !(anyHas "network-online.target" ((lib.toList (onedriveUnit.After or [ ])) ++ (lib.toList (onedriveUnit.Wants or [ ]))))) "StartLimit missing or network-online.target ordering is back") ]
    [ "OneDrive unit restarts on failure" (chk (onedrive.Service.Restart == "on-failure") "Restart is ${onedrive.Service.Restart}") ]

    [ "tkgate and sqldeveloper grant X access only to the local user (si:localuser:), never bare xhost +" (chk (lib.all (n: let t = scriptText n; in lib.hasInfix "xhostEntry=\"si:localuser:" t && lib.hasInfix "\"+$xhostEntry\"" t && lib.hasInfix "\"-$xhostEntry\"" t && !(lib.hasInfix "xhost +" t)) [ "tkgate-school" "sqldeveloper-school" ]) "xhost line is not the narrow localuser form with revoke") ]
    [ "idea-school exports GIT_CONFIG_GLOBAL to the git config under ~/.config/git" (chk (let t = scriptText "idea-school"; in lib.hasInfix "XDG_CONFIG_HOME=" t && lib.hasInfix "GIT_CONFIG_GLOBAL=\"$HOME/.config/git/config\"" t) "GIT_CONFIG_GLOBAL not exported") ]
    [ "school year directories are 2nd/3rd, not 2st/3st" (chk (lib.hasInfix "year/2nd/3-semester" createDirs && lib.hasInfix "year/3rd/5-semester" createDirs && !(lib.hasInfix "year/2st" createDirs) && !(lib.hasInfix "year/3st" createDirs)) "year dir names wrong in createSchoolDirs") ]
    [ "niri and mango autostart nvim in the school workspace" (chk (anyHas "nvim" c.myconfig.programs.niri.execOnce && anyHas "nvim" c.myconfig.programs.mango.execOnce) "nvim missing from niri or mango execOnce") ]
    [ "guiScale is derived from the monitors, not the 1.0 fallback" (chk (lib.length scales == 1 && scale != 1.0 && lib.hasInfix "uiScale=${scaleStr}\"" (scriptText "sqldeveloper-school")) "scale ${scaleStr}, script uiScale ${toString (uiScaleOf (scriptText "sqldeveloper-school"))}") ]

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
