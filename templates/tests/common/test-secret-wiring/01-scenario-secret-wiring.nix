let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  fx = import ../../lib/fixture-host.nix flake;
  nixosHosts =
    if hasNixos then {
      nixos-desktop = flake.nixosConfigurations.nixos-desktop;
      nixos-laptop = flake.nixosConfigurations.nixos-laptop;
    } else { };
  darwinHosts = { Krits-MacBook-Pro = flake.darwinConfigurations.Krits-MacBook-Pro; };
  allHosts = nixosHosts // darwinHosts;
  nas = flake.homeConfigurations."krit@Nicol-NAS";

  commonYaml = "${flake.outPath}/users/krit/common/sops/krit-common-secrets-sops.yaml";
  runSecrets = name: "/run/secrets/${name}";

  failures = list: if list == [ ] then "ok" else "FAIL: ${lib.concatStringsSep "; " list}";

  perHost = hosts: f: failures (lib.concatLists (lib.mapAttrsToList (n: h: map (m: "${n}: ${m}") (f h)) hosts));

  userOf = h: h.config.myconfig.constants.user;
  secretsOf = h: h.config.sops.secrets;
  mcpOf = h: h.config.myconfig.krit.programs.claude-code-personal.mcpSecrets;

  yamlKeys = file:
    map (l: lib.head (lib.splitString ":" l))
      (lib.filter (l: l != "" && !(lib.hasPrefix " " l) && !(lib.hasPrefix "#" l) && lib.hasInfix ":" l)
        (lib.splitString "\n" (builtins.readFile file)));

  fileOf = h: s: if s.sopsFile or null != null then s.sopsFile else h.config.sops.defaultSopsFile;

  withModules = host: modules: host.extendModules { inherit modules; };

  failedAssertions = h: map (a: a.message) (lib.filter (a: !a.assertion) h.config.assertions);

  tbSopsFile = "${flake.outPath}/templates/tests/common/test-secret-wiring/fake-thunderbird-sops.yaml";
  tbAccounts = [
    {
      name = "fakemail";
      addressLocalSecretName = "fake_tb_one_local";
      addressDomainSecretName = "fake_tb_one_domain";
      realName = "Fake One";
      primary = true;
      authentication = "login";
      passwordSecretName = "fake_tb_one_password";
    }
    {
      name = "fakeoauth";
      addressLocalSecretName = "fake_tb_two_local";
      addressDomainSecretName = "fake_tb_two_domain";
      realName = "Fake Two";
      primary = false;
      passwordSecretName = null;
    }
  ];
  tbModule = {
    myconfig.programs.thunderbird = {
      enable = true;
      sopsFile = tbSopsFile;
      accounts = tbAccounts;
    };
  };
  tbForced = host: withModules host [ ({ lib, ... }: { myconfig.programs.thunderbird = { enable = lib.mkForce true; sopsFile = lib.mkForce tbSopsFile; accounts = lib.mkForce tbAccounts; }; }) ];
  tbOnHosts = (if hasNixos then { template-host-minimal = fx.mkNixos [ tbModule ]; } else { }) // lib.mapAttrs (_: tbForced) darwinHosts;
  tbExpectedPath = host: user:
    if host.pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}/Library/Thunderbird/Profiles/default/user.js"
    else "/home/${user}/.thunderbird/default/user.js";
  tbSecretNames = lib.unique (lib.concatMap
    (a: [ a.addressLocalSecretName a.addressDomainSecretName ] ++ lib.optional (a.passwordSecretName != null) a.passwordSecretName)
    tbAccounts);
  nasWiring = h:
    let
      n = h.config.myconfig.krit.services.nas;
      s = secretsOf h;
      eq = label: actual: expected: lib.optional (actual != expected) "${label}: ${actual} != ${expected}";
      consumers = [
        { mod = "sshfs"; opt = "identityFile"; secret = "nas_ssh_key"; }
        { mod = "smb"; opt = "credentialsFile"; secret = "nas-krit-credentials"; }
        { mod = "desktop-borg-backup"; opt = "passphraseFile"; secret = "borg-passphrase"; }
        { mod = "desktop-borg-backup"; opt = "sshKeyPath"; secret = "borg-private-key"; }
        { mod = "laptop-borg-backup"; opt = "passphraseFile"; secret = "borg-passphrase"; }
        { mod = "laptop-borg-backup"; opt = "sshKeyPath"; secret = "borg-private-key"; }
      ];
      enabled = lib.filter (x: n.${x.mod}.enable) consumers;
      disabled = lib.filter (x: !n.${x.mod}.enable) consumers;
      needed = lib.unique (map (x: x.secret) enabled);
      ownSecrets = lib.unique (map (x: x.secret) consumers);
      pin = h.config.programs.ssh.knownHosts."nicol-nas-tailnet" or null;
    in
    lib.concatMap
      (x:
        lib.optional (!(s ? ${x.secret})) "${x.mod}.${x.opt}: enabled but ${x.secret} is not declared"
        ++ lib.optionals (s ? ${x.secret}) (
          eq "${x.mod}.${x.opt}" n.${x.mod}.${x.opt} s.${x.secret}.path
          ++ eq "${x.mod}.${x.opt} run path" n.${x.mod}.${x.opt} (runSecrets x.secret)
        ))
      enabled
    ++ map (x: "${x.mod}.${x.opt} is wired (${n.${x.mod}.${x.opt}}) although ${x.mod} is disabled") (lib.filter (x: n.${x.mod}.${x.opt} != "") disabled)
    ++ map (name: "${name} is declared but no enabled consumer needs it") (lib.filter (name: s ? ${name} && !(lib.elem name needed)) ownSecrets)
    ++ lib.optionals n.opencloud-mount.enable (eq "opencloud-mount.secretsFile" n.opencloud-mount.secretsFile h.config.sops.templates."davfs-secrets".path)
    ++ lib.optional (pin == null) "nicol-nas-tailnet knownHosts pin missing (module nas-identity)"
    ++ lib.optionals (pin != null) (
      lib.optional (pin.publicKey != n.hostKey) "knownHosts pin key differs from krit.services.nas.hostKey"
      ++ lib.optional (!(lib.elem n.host pin.hostNames && lib.elem n.tailnetIp pin.hostNames)) "pin hostNames lack nas.host or nas.tailnetIp: ${builtins.toJSON pin.hostNames}"
    );

  nasAllOn = {
    myconfig.krit.services.nas = {
      sshfs.enable = true;
      smb.enable = true;
      desktop-borg-backup.enable = true;
      laptop-borg-backup.enable = true;
    };
  };
in
{
  check-mcp-secrets-declared = perHost allHosts (h:
    let s = secretsOf h; user = userOf h; in
    lib.concatMap
      (m:
        if !(s ? ${m.sopsSecret}) then [ "${m.sopsSecret} not in sops.secrets" ]
        else
          lib.optional (s.${m.sopsSecret}.owner != user) "${m.sopsSecret} owner ${s.${m.sopsSecret}.owner} != ${user}"
          ++ lib.optional (s.${m.sopsSecret}.path != runSecrets m.sopsSecret) "${m.sopsSecret} path ${s.${m.sopsSecret}.path} != ${runSecrets m.sopsSecret}"
          ++ lib.optional (toString s.${m.sopsSecret}.sopsFile != toString commonYaml) "${m.sopsSecret} sopsFile not the common yaml")
      (mcpOf h));

  check-mcp-secrets-gated-on-personal = perHost allHosts (h:
    let
      names = map (m: m.sopsSecret) (mcpOf h);
      personal = value: withModules h [ ({ lib, ... }: { myconfig.krit.programs.claude-code-personal.enable = lib.mkForce value; }) ];
      off = secretsOf (personal false);
      on = secretsOf (personal true);
    in
    lib.optional (names == [ ]) "mcpSecrets empty: check would be vacuous"
    ++ map (n: "personal off: ${n} still declared") (lib.filter (n: off ? ${n}) names)
    ++ map (n: "personal on: ${n} not declared") (lib.filter (n: !(on ? ${n})) names));

  check-yaml-key-lookup-bites =
    let keys = yamlKeys commonYaml; in
    failures (
      lib.optional (!lib.elem "tailscale_key" keys) "yaml parser misses a known key"
      ++ lib.optional (lib.elem "no_such_key_xyz" keys) "yaml parser invents keys"
      ++ lib.optional (lib.length keys < 10) "yaml parser found suspiciously few keys"
    );

  check-mcp-secrets-in-yaml = perHost allHosts (h:
    let keys = yamlKeys commonYaml; in
    map (m: "${m.sopsSecret} missing from common yaml") (lib.filter (m: !(lib.elem m.sopsSecret keys)) (mcpOf h)));

  check-mcp-nas-home-wrapper =
    let
      cfg = nas.config;
      s = cfg.sops.secrets;
      mcp = cfg.myconfig.krit.programs.claude-code-personal.mcpSecrets;
      env = cfg.myconfig.krit.programs.claude-code-personal.mcpEnv;
      wrapper = lib.filter (p: (p.name or "") == "claude") cfg.home.packages;
      text = if wrapper == [ ] then "" else builtins.unsafeDiscardStringContext ((lib.head wrapper).text or "");
      exported = lib.concatMap
        (l: let m = builtins.match "export ([A-Za-z_][A-Za-z0-9_]*)=.*" l; in if m == null then [ ] else m)
        (lib.splitString "\n" text);
      secretPaths = map (m: builtins.unsafeDiscardStringContext s.${m.sopsSecret}.path) (lib.filter (m: s ? ${m.sopsSecret}) mcp);
    in
    failures (
      lib.optional (wrapper == [ ]) "no `claude` wrapper in home.packages for the home-only build"
      ++ lib.optional (env == { }) "NAS mcpEnv empty: no-secret check would be vacuous"
      ++ map (m: "${m.sopsSecret} not in home sops.secrets") (lib.filter (m: !(s ? ${m.sopsSecret})) mcp)
      ++ lib.optionals (wrapper != [ ]) (
        lib.optional (lib.sort lib.lessThan exported != lib.sort lib.lessThan (lib.attrNames env))
          "wrapper exports ${builtins.toJSON exported}, expected exactly the mcpEnv keys ${builtins.toJSON (lib.attrNames env)}"
        ++ map (needle: "wrapper reads a secret (${needle})")
          (lib.filter (needle: lib.hasInfix needle text) ([ "$(cat" "/run/secrets" ] ++ secretPaths))
      )
    );

  check-cache-token-secrets = perHost allHosts (h:
    let
      c = h.config.myconfig;
      s = secretsOf h;
      one = label: p:
        let n = baseNameOf p; in
        lib.optional (p == "") "${label}.authTokenPath empty"
        ++ lib.optional (p != "" && !(s ? ${n})) "${label}: secret ${n} not declared"
        ++ lib.optional (p != "" && s ? ${n} && s.${n}.path != p) "${label}: ${p} != declared path ${s.${n}.path}"
        ++ lib.optional (p != "" && s ? ${n} && !(lib.elem n (yamlKeys (fileOf h s.${n})))) "${label}: ${n} missing from its sops yaml";
    in
    one "cachix" c.cachix.authTokenPath ++ one "attic" c.attic.authTokenPath
    ++ lib.optional (!lib.hasPrefix "${c.attic.cacheName}:" c.attic.publicKey) "attic.publicKey does not start with ${c.attic.cacheName}:"
    ++ lib.optional (!lib.hasPrefix "${c.cachix.name}.cachix.org-" c.cachix.publicKey) "cachix.publicKey does not start with ${c.cachix.name}.cachix.org-"
    ++ lib.optional (!(h.config.nix.settings ? netrc-file)) "nix.settings.netrc-file unset"
    ++ lib.optional (h.config.nix.settings.netrc-file or "" != h.config.sops.templates."attic-netrc".path) "netrc-file != attic-netrc template path"
    ++ lib.optional (!lib.hasInfix h.config.sops.placeholder.attic-push-token h.config.sops.templates."attic-netrc".content) "attic-netrc does not embed the attic-push-token placeholder");

  check-attic-assertion-bites =
    let
      bad = withModules (lib.head (lib.attrValues allHosts)) [
        ({ lib, ... }: { myconfig.attic.authTokenPath = lib.mkForce "/run/secrets/no-such-token"; })
      ];
      good = lib.head (lib.attrValues allHosts);
    in
    failures (
      lib.optional (failedAssertions good != [ ]) "baseline already has failing assertions"
      ++ lib.optional (!(lib.any (m: lib.hasInfix "no-such-token" m) (failedAssertions bad))) "attic assertion did not fire for an undeclared token secret"
    );

  check-github-pat-include = perHost allHosts (h:
    let p = (secretsOf h).github_fg_pat_token_nix.path; in
    lib.optional (!lib.hasInfix "!include ${p}" h.config.nix.extraOptions) "nix.extraOptions does not !include ${p}"
    ++ lib.optional (!(lib.elem "github_fg_pat_token_nix" (yamlKeys commonYaml))) "PAT key missing from common yaml");

  check-github-pat-mode-consistent =
    let
      perms = lib.mapAttrs
        (_: h:
          let t = (secretsOf h).github_fg_pat_token_nix; in
          { inherit (t) owner mode; })
        allHosts;
      expected = lib.mapAttrs (_: h: { owner = userOf h; mode = "0400"; }) allHosts;
    in
    if perms == expected then "ok" else "FAIL: PAT owner/mode is not <user>/0400 on every host: ${builtins.toJSON perms}";

  check-sopsfiles-and-keys = perHost allHosts (h:
    lib.concatLists (lib.mapAttrsToList
      (n: s:
        let f = fileOf h s; in
        if !(builtins.pathExists f) then [ "${n}: sopsFile ${toString f} does not exist" ]
        else lib.optional (!(lib.elem (s.key or n) (yamlKeys f))) "${n}: key missing from ${baseNameOf (toString f)}")
      (secretsOf h)));

  check-davfs-secrets-template = perHost nixosHosts (h:
    let t = h.config.sops.templates."davfs-secrets"; in
    lib.optional (t.mode != "0600") "mode ${t.mode} != 0600"
    ++ lib.optional (t.owner != "root") "owner ${t.owner} != root"
    ++ lib.optional (!lib.hasInfix h.config.sops.placeholder.nas_opencloud_user t.content) "no user placeholder"
    ++ lib.optional (!lib.hasInfix h.config.sops.placeholder.nas_opencloud_pass t.content) "no pass placeholder");

  check-nas-wiring-nixos = perHost nixosHosts (h:
    nasWiring h
    ++ lib.optional (h.config.services.tailscale.authKeyFile != runSecrets "tailscale_key") "tailscale.authKeyFile: ${toString h.config.services.tailscale.authKeyFile} != ${runSecrets "tailscale_key"}");

  check-nas-wiring-fixture =
    let
      on = fx.mkNixos [ nasAllOn ];
      broken = fx.mkNixos [ nasAllOn { myconfig.krit.services.nas.sshfs.identityFile = lib.mkForce "/wrong/path"; } ];
      nOn = on.config.myconfig.krit.services.nas;
    in
    if !hasNixos then "ok"
    else
      failures (
        map (m: "fixture: ${m}") (nasWiring on)
        ++ lib.optional (!(nOn.sshfs.enable && nOn.smb.enable && nOn.desktop-borg-backup.enable && nOn.laptop-borg-backup.enable)) "fixture: not every NAS consumer is enabled"
        ++ lib.optional (nasWiring broken == [ ]) "control: a mis-wired sshfs.identityFile was not detected"
        ++ map (m: "control: minimal host without NAS consumers: ${m}") (nasWiring (fx.mkNixos [ ]))
      );

  check-nas-secret-ownership-bites =
    let
      off = fx.mkNixos [ ];
      on = fx.mkNixos [{ myconfig.krit.services.nas.sshfs.enable = true; }];
    in
    if !hasNixos then "ok"
    else
      failures (
        lib.optional (secretsOf off ? nas_ssh_key) "sshfs off: nas_ssh_key still declared"
        ++ lib.optional (off.config.myconfig.krit.services.nas.sshfs.identityFile != "") "sshfs off: identityFile still wired"
        ++ lib.optional (!(secretsOf on ? nas_ssh_key)) "control: sshfs on did not declare nas_ssh_key"
        ++ lib.optional (on.config.myconfig.krit.services.nas.sshfs.identityFile != (runSecrets "nas_ssh_key")) "control: sshfs on did not wire identityFile to /run/secrets/nas_ssh_key"
      );

  check-nas-secrets-darwin = perHost darwinHosts (h:
    let
      s = secretsOf h;
      need = [ "nas_ssh_key" "nas-krit-credentials" "nas_opencloud_user" "nas_opencloud_pass" "borg-passphrase" "borg-private-key" "tailscale_key" ];
      nasCfg = h.config.myconfig.krit.services.nas;
      enabledNeeds = lib.optionals (nasCfg.sshfs.enable or false) [ "nas_ssh_key" ]
        ++ lib.optionals (nasCfg.smb.enable or false) [ "nas-krit-credentials" ]
        ++ lib.optionals (nasCfg.opencloud.enable or false) [ "nas_opencloud_user" "nas_opencloud_pass" ]
        ++ lib.optionals (nasCfg.Krits-MacBook-Pro-borg-backup.enable or false) [ "borg-passphrase" "borg-private-key" ];
    in
    map (n: "${n} used by an enabled NAS module but not declared") (lib.filter (n: !(s ? ${n})) enabledNeeds)
    ++ map (n: "${n} not in its yaml") (lib.filter (n: s ? ${n} && !(lib.elem n (yamlKeys (fileOf h s.${n})))) need));

  check-thunderbird-forced = perHost tbOnHosts (h:
    let
      user = userOf h;
      t = h.config.sops.templates."tb-user-js";
      s = secretsOf h;
      primaries = lib.filter (a: a.primary) tbAccounts;
    in
    lib.optional (t.path != tbExpectedPath h user) "template path ${t.path} != ${tbExpectedPath h user}"
    ++ lib.optional (t.owner != user) "template owner ${t.owner} != ${user}"
    ++ lib.optional (lib.length primaries > 1) "more than one primary account"
    ++ lib.concatMap
      (n:
        if !(s ? ${n}) then [ "${n} not declared" ]
        else lib.optional (s.${n}.owner != user) "${n} owner ${s.${n}.owner}"
        ++ lib.optional (toString s.${n}.sopsFile != toString tbSopsFile) "${n} sopsFile differs"
        ++ lib.optional (!lib.elem n (yamlKeys tbSopsFile)) "${n} missing from yaml")
      tbSecretNames
    ++ lib.optionals (h.pkgs.stdenv.hostPlatform.isDarwin == false) (
      let off = fx.mkNixos [ ]; in
      lib.optional (off.config.sops.templates ? "tb-user-js") "control: tb-user-js template present with thunderbird disabled"
      ++ map (n: "control: ${n} declared with thunderbird disabled") (lib.filter (n: off.config.sops.secrets ? ${n}) tbSecretNames)
    ));

  check-ssh-key-paths = perHost allHosts (h:
    let
      user = userOf h;
      isDarwin = h.pkgs.stdenv.hostPlatform.isDarwin;
      home = if isDarwin then "/Users/${user}" else "/home/${user}";
      schoolSpec = if isDarwin then null else h.config.specialisation.school.configuration;
      schoolSecrets = if isDarwin then secretsOf h else (schoolSpec.config or schoolSpec).sops.secrets;
      eqIn = s: n: p: lib.optional (!(s ? ${n})) "${n} not declared"
        ++ lib.optional (s ? ${n} && s.${n}.path != "${home}/.ssh/${p}") "${n} path ${s.${n}.path or "?"} != ${home}/.ssh/${p}";
      eq = eqIn (secretsOf h);
      leakedIn = label: s: map (n: "${n} declared in ${label}") (lib.filter (n: s ? ${n}) [ "school_ssh_key" "school_ssh_pub" ]);
      otherSpecs = lib.filter (n: h.config.specialisation ? ${n}) [ "guest" "secure-travel" ];
    in
    eq "github_general_ssh_key" "id_github" ++ eq "github_general_ssh_pub" "id_github.pub"
    ++ eqIn schoolSecrets "school_ssh_key" "id_school" ++ eqIn schoolSecrets "school_ssh_pub" "id_school.pub"
    ++ lib.optionals (!isDarwin) (
      leakedIn "the base config" (secretsOf h)
      ++ lib.concatMap
        (n: leakedIn "specialisation ${n}" (let sp = h.config.specialisation.${n}.configuration; in (sp.config or sp).sops.secrets))
        otherSpecs
      ++ lib.optional (otherSpecs == [ ]) "no guest/secure-travel specialisation found: the leak scan would be vacuous"
    ));
  check-mcp-nas-launchers =
    let
      cfg = nas.config;
      nc = builtins.unsafeDiscardStringContext;
      launcher = pkgs: n: lib.filter (p: (p.name or "") == n) pkgs;
      pkgsOf = c: c.home.packages;
      textOf = n: let l = launcher (pkgsOf cfg) n; in if l == [ ] then "" else nc ((lib.head l).text or "");
      pathOf = sec: nc cfg.sops.secrets.${sec}.path;
      ctx = textOf "claude-mcp-context7";
      gh = textOf "claude-mcp-github";
      execLines = t: lib.filter (l: lib.hasInfix "exec " l) (lib.splitString "\n" t);
      one = n: sec: t:
        if t == "" then [ "${n} missing from NAS home.packages" ]
        else
          lib.optional (!lib.hasInfix (pathOf sec) t) "${n} does not read the HM sops path ${pathOf sec}"
          ++ lib.optional (!lib.hasInfix "/.config/sops-nix/" (pathOf sec)) "${sec} HM path is not under .config/sops-nix"
          ++ lib.optional (lib.hasInfix "/run/secrets" t) "${n} references /run/secrets"
          ++ lib.optional (lib.hasInfix "--api-key" t) "${n} passes --api-key"
          ++ lib.optional (execLines t == [ ]) "${n} has no exec line (argv check would be vacuous)"
          ++ lib.concatMap (l: lib.optional (lib.hasInfix "$(cat" l || lib.hasInfix (pathOf sec) l) "${n} exec line carries the secret: ${l}") (execLines t);
      hasMcp = c: lib.filter (p: lib.hasPrefix "claude-mcp-" (p.name or "")) (pkgsOf c);
      withoutCtx = nas.extendModules {
        modules = [
          ({ lib, ... }: {
            myconfig.krit.programs.claude-code-personal.mcpSecrets = lib.mkForce
              (lib.filter (m: m.sopsSecret != "claude_mcp_context7_api_key") cfg.myconfig.krit.programs.claude-code-personal.mcpSecrets);
          })
        ];
      };
    in
    failures (
      one "claude-mcp-context7" "claude_mcp_context7_api_key" ctx
      ++ one "claude-mcp-github" "claude_mcp_github_token" gh
      ++ lib.optional (gh != "" && !lib.hasInfix "--header 'Authorization:\${AUTH_HEADER}'" gh) "github header is not the literal Authorization:\${AUTH_HEADER}"
      ++ lib.optional (map (p: p.name) (hasMcp withoutCtx.config) != [ "claude-mcp-github" ]) "control: dropping the context7 secret must drop exactly its launcher"
      ++ lib.optionals hasNixos (lib.optional
        (hasMcp nixosHosts.nixos-desktop.config.home-manager.users.${userOf nixosHosts.nixos-desktop} != [ ])
        "integrated NixOS home gained claude-mcp-* launchers (home-only gate broken)")
    );

  check-thunderbird-profile-dirs =
    let
      offDarwin = h: withModules h [ ({ lib, ... }: { myconfig.programs.thunderbird.enable = lib.mkForce false; }) ];
      nixosOne = h:
        let
          user = userOf h;
          grp = h.config.users.users.${user}.group;
          a = h.config.system.activationScripts.thunderbirdProfileDirs or null;
          t = if a == null then "" else a.text;
          offH = fx.mkNixos [ ];
        in
        lib.optional (a == null) "thunderbirdProfileDirs activation script missing"
        ++ lib.optionals (a != null) (
          lib.optional (!lib.hasInfix "install -d -o ${user} -g ${grp} -m 0700" t) "install -d -o ${user} -g ${grp} -m 0700 not in script"
          ++ lib.optional (!lib.elem "/home/${user}/.thunderbird \\" (map lib.trim (lib.splitString "\n" t))) "parent .thunderbird dir not created"
          ++ lib.optional (!lib.hasInfix "/home/${user}/.thunderbird/default" t) "profile dir default not created"
          ++ lib.optional (!(lib.elem "users" a.deps && lib.elem "groups" a.deps)) "deps lack users/groups: ${builtins.toJSON a.deps}"
        )
        ++ lib.optional (offH.config.system.activationScripts ? thunderbirdProfileDirs) "control: script still present with thunderbird disabled";
      darwinOne = h0:
        let
          h = tbForced h0;
          user = userOf h;
          t = h.config.system.activationScripts.preActivation.text or "";
          base = "/Users/${user}/Library/Thunderbird";
          dirs = [ base "${base}/Profiles" "${base}/Profiles/default" ];
          tLines = map (l: lib.removeSuffix " \\" (lib.trim l)) (lib.splitString "\n" t);
          offT = (offDarwin h0).config.system.activationScripts.preActivation.text or "";
        in
        lib.optional (!lib.hasInfix "mkdir -p ${base}/Profiles/default" t) "mkdir -p profile dir missing"
        ++ lib.optional (!lib.hasInfix "chown ${user}:staff" t) "chown ${user}:staff missing"
        ++ lib.optional (!lib.hasInfix "chmod 0700" t) "chmod 0700 missing"
        ++ map (d: "${d} not covered by chown/chmod") (lib.filter (d: lib.count (l: l == d) tLines != 2) dirs)
        ++ lib.optional (lib.hasInfix "Library/Thunderbird" offT) "control: preActivation still mentions Thunderbird with thunderbird disabled";
    in
    failures (
      lib.concatLists (lib.mapAttrsToList (n: h: map (m: "${n}: ${m}") (nixosOne h)) (lib.optionalAttrs hasNixos { inherit (tbOnHosts) template-host-minimal; }))
      ++ lib.concatLists (lib.mapAttrsToList (n: h: map (m: "${n}: ${m}") (darwinOne h)) darwinHosts)
    );
}
