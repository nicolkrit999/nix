let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
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
  mcpOf = h: h.config.myconfig.programs.claude-code.mcpSecrets;

  yamlKeys = file:
    map (l: lib.head (lib.splitString ":" l))
      (lib.filter (l: l != "" && !(lib.hasPrefix " " l) && !(lib.hasPrefix "#" l) && lib.hasInfix ":" l)
        (lib.splitString "\n" (builtins.readFile file)));

  fileOf = h: s: if s.sopsFile or null != null then s.sopsFile else h.config.sops.defaultSopsFile;

  withModules = host: modules: host.extendModules { inherit modules; };

  failedAssertions = h: map (a: a.message) (lib.filter (a: !a.assertion) h.config.assertions);

  tbAccounts = flake.nixosConfigurations.nixos-desktop.config.myconfig.programs.thunderbird.accounts;
  tbSopsFile = flake.nixosConfigurations.nixos-desktop.config.myconfig.programs.thunderbird.sopsFile;
  tbForced = host: withModules host [
    ({ lib, ... }: {
      myconfig.programs.thunderbird.enable = lib.mkForce true;
      myconfig.programs.thunderbird.sopsFile = lib.mkForce tbSopsFile;
      myconfig.programs.thunderbird.accounts = lib.mkForce tbAccounts;
    })
  ];
  tbExpectedPath = host: user:
    if host.pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${user}/Library/Thunderbird/Profiles/default/user.js"
    else "/home/${user}/.thunderbird/default/user.js";
  tbSecretNames = lib.unique (lib.concatMap
    (a: [ a.addressLocalSecretName a.addressDomainSecretName ] ++ lib.optional (a.passwordSecretName != null) a.passwordSecretName)
    tbAccounts);
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

  check-yaml-key-lookup-bites =
    let keys = yamlKeys commonYaml; in
    failures (
      lib.optional (!lib.elem "tailscale_key" keys) "yaml parser misses a known key"
      ++ lib.optional (lib.elem "no_such_key_xyz" keys) "yaml parser invents keys"
      ++ lib.optional (lib.length keys < 10) "yaml parser found suspiciously few keys"
    );

  check-mcp-envvars-unique = perHost (allHosts // { Nicol-NAS = { config = { myconfig = nas.config.myconfig; }; }; }) (h:
    let vars = map (m: m.envVar) h.config.myconfig.programs.claude-code.mcpSecrets;
    in lib.optional (vars == [ ]) "empty mcpSecrets"
      ++ lib.optional (lib.length vars != lib.length (lib.unique vars)) "duplicate envVar in ${builtins.toJSON vars}"
      ++ lib.optional (lib.any (v: v == "") vars) "empty envVar");

  check-mcp-secrets-in-yaml = perHost allHosts (h:
    let keys = yamlKeys commonYaml; in
    map (m: "${m.sopsSecret} missing from common yaml") (lib.filter (m: !(lib.elem m.sopsSecret keys)) (mcpOf h)));

  check-mcp-nas-home-wrapper =
    let
      cfg = nas.config;
      s = cfg.sops.secrets;
      mcp = cfg.myconfig.programs.claude-code.mcpSecrets;
      wrapper = lib.filter (p: (p.name or "") == "claude") cfg.home.packages;
      text = if wrapper == [ ] then "" else (lib.head wrapper).text or "";
    in
    failures (
      lib.optional (wrapper == [ ]) "no `claude` wrapper in home.packages for the home-only build"
      ++ map (m: "${m.sopsSecret} not in home sops.secrets") (lib.filter (m: !(s ? ${m.sopsSecret})) mcp)
      ++ lib.optionals (wrapper != [ ]) (lib.concatMap
        (m: lib.optional (s ? ${m.sopsSecret} && !(lib.hasInfix "export ${m.envVar}=" text && lib.hasInfix s.${m.sopsSecret}.path text))
          "wrapper lacks export of ${m.envVar} from ${m.sopsSecret}")
        mcp)
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
      modes = lib.mapAttrs (_: h: (secretsOf h).github_fg_pat_token_nix.mode) allHosts;
      vals = lib.unique (lib.attrValues modes);
    in
    if lib.length vals == 1 then "ok" else "FAIL: PAT mode differs across hosts: ${builtins.toJSON modes}";

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
    let
      n = h.config.myconfig.krit.services.nas;
      s = secretsOf h;
      eq = label: actual: expected: lib.optional (actual != expected) "${label}: ${actual} != ${expected}";
    in
    eq "sshfs.identityFile" n.sshfs.identityFile s.nas_ssh_key.path
    ++ eq "sshfs.identityFile path" n.sshfs.identityFile (runSecrets "nas_ssh_key")
    ++ eq "smb.credentialsFile" n.smb.credentialsFile (runSecrets "nas-krit-credentials")
    ++ eq "desktop-borg.passphraseFile" n.desktop-borg-backup.passphraseFile (runSecrets "borg-passphrase")
    ++ eq "desktop-borg.sshKeyPath" n.desktop-borg-backup.sshKeyPath (runSecrets "borg-private-key")
    ++ eq "laptop-borg.passphraseFile" n.laptop-borg-backup.passphraseFile (runSecrets "borg-passphrase")
    ++ eq "laptop-borg.sshKeyPath" n.laptop-borg-backup.sshKeyPath (runSecrets "borg-private-key")
    ++ eq "opencloud-mount.secretsFile" n.opencloud-mount.secretsFile h.config.sops.templates."davfs-secrets".path
    ++ eq "tailscale.authKeyFile" h.config.services.tailscale.authKeyFile (runSecrets "tailscale_key"));

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
    lib.optional (enabledNeeds == [ ]) "no NAS module enabled on this host: check would be vacuous"
    ++ map (n: "${n} used by an enabled NAS module but not declared") (lib.filter (n: !(s ? ${n})) enabledNeeds)
    ++ map (n: "${n} not in its yaml") (lib.filter (n: s ? ${n} && !(lib.elem n (yamlKeys (fileOf h s.${n})))) need));

  check-thunderbird-forced = perHost allHosts (h0:
    let
      h = tbForced h0;
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
      tbSecretNames);

  check-ssh-key-paths = perHost allHosts (h:
    let
      s = secretsOf h;
      user = userOf h;
      home = if h.pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";
      eq = n: p: lib.optional (!(s ? ${n})) "${n} not declared"
        ++ lib.optional (s ? ${n} && s.${n}.path != "${home}/.ssh/${p}") "${n} path ${s.${n}.path or "?"} != ${home}/.ssh/${p}";
    in
    eq "github_general_ssh_key" "id_github" ++ eq "github_general_ssh_pub" "id_github.pub"
    ++ eq "school_ssh_key" "id_school" ++ eq "school_ssh_pub" "id_school.pub");
}
