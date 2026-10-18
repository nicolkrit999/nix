let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  host = flake.darwinConfigurations.Krits-MacBook-Pro;
  config = host.config;
  pkgs = host.pkgs;
  my = config.myconfig;
  c = my.constants;
  user = c.user;
  hm = config.home-manager.users.${user};

  pnames = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.environment.systemPackages;
  sysNames = pnames config;

  withBrowser = host.extendModules {
    modules = [ ({ lib, ... }: { myconfig.constants.browser = lib.mkForce "firefox"; }) ];
  };

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkEq = name: actual: expected:
    check name (actual == expected) "expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  checkHas = name: list: x:
    check name (builtins.elem x list) "${builtins.toJSON x} missing from ${builtins.toJSON list}";

  linuxOnlyTools = [ "ethtool" "iw" "ntopng" "suricata" "ptcpdump" "rsyslog" "wavemon" "sane-airscan" "traceroute" "wireless-tools" ];
  leakedLinuxTools = builtins.filter (n: builtins.elem n sysNames) linuxOnlyTools;

  translatedEditor = if c.editor == "nvim" then "neovim" else c.editor;
  resolvedNames = [ c.terminal.name c.fileManager translatedEditor ];
  missingPkgs = builtins.filter (n: !(builtins.hasAttr n pkgs)) resolvedNames;

  mcpNames = map (s: s.sopsSecret) my.programs.claude-code.mcpSecrets;
  missingMcp = builtins.filter (n: !(config.sops.secrets ? ${n})) mcpNames;

  withoutCask = host.extendModules {
    modules = [ ({ lib, ... }: { homebrew.casks = lib.mkForce [ ]; }) ];
  };
  withAlacrittyTerminal = host.extendModules {
    modules = [ ({ lib, ... }: { myconfig.constants.terminal.name = lib.mkForce "alacritty"; }) ];
  };

  nixAppsDir = "/Applications/Nix Apps/";
  hmAppsDir = "${config.users.users.${user}.home}/Applications/Home Manager Apps/";
  appBase = dir: e: lib.removeSuffix ".app" (lib.removePrefix dir e);
  appNames = pkg: map lib.toLower (builtins.filter (x: x != null) [ (pkg.longName or null) (pkg.pname or null) ]);
  nixAppNames = cfg: lib.concatMap appNames cfg.environment.systemPackages;
  hmAppNames = cfg: lib.concatMap appNames cfg.home-manager.users.${user}.home.packages;
  danglingDock = cfg: entries:
    builtins.filter
      (e:
        (lib.hasPrefix nixAppsDir e && !(builtins.elem (lib.toLower (appBase nixAppsDir e)) (nixAppNames cfg)))
        || (lib.hasPrefix hmAppsDir e && !(builtins.elem (lib.toLower (appBase hmAppsDir e)) (hmAppNames cfg))))
      entries;
  dock = map (e: if builtins.isString e then e else e.tile-data.file-data._CFURLString) config.system.defaults.dock.persistent-apps;
  fakeEntries = dock ++ [ "${hmAppsDir}Firefox.app" "${hmAppsDir}Visual Studio Code.app" ];

  termName = cfg: cfg.myconfig.constants.terminal.name;
  termEnabled = cfg: cfg.myconfig.krit.programs.${termName cfg}.enable or false;

  browserPnames = [ "firefox" "librewolf" "chromium" ];
  browserHits = builtins.filter (n: builtins.elem n sysNames) browserPnames;
in
{
  check-primary-user = checkEq "system.primaryUser == constants.user" config.system.primaryUser user;
  check-user-literal = checkEq "constants.user" user "krit";
  check-uid = checkEq "users.users.<user>.uid == constants.uid" config.users.users.${user}.uid c.uid;
  check-uid-501 = checkEq "constants.uid" c.uid 501;
  check-known-users = checkHas "users.knownUsers" config.users.knownUsers user;
  check-home-dir = checkEq "users.users.<user>.home" config.users.users.${user}.home "/Users/${user}";
  check-hm-home-dir = checkEq "HM home.homeDirectory == users.users.<user>.home" hm.home.homeDirectory config.users.users.${user}.home;
  check-shell-registered =
    let sh = config.users.users.${user}.shell; in
    checkHas "environment.shells contains user shell" config.environment.shells "/run/current-system/sw${sh.shellPath}";

  check-nixbld-gid = checkEq "ids.gids.nixbld" config.ids.gids.nixbld 350;
  check-gc-off = checkEq "nix.gc.automatic" config.nix.gc.automatic false;
  check-experimental-features =
    let ef = config.nix.settings.experimental-features; in
    check "nix.settings.experimental-features" (builtins.elem "flakes" ef && builtins.elem "nix-command" ef)
      "need flakes and nix-command, got ${builtins.toJSON ef}";
  check-host-platform = checkEq "nixpkgs.hostPlatform.system" config.nixpkgs.hostPlatform.system "aarch64-darwin";

  check-sops-key-env-consistent =
    let k = config.sops.age.keyFile; in
    check "environment.variables.SOPS_AGE_KEY_FILE == sops.age.keyFile == sops.environment.SOPS_AGE_KEY_FILE"
      (config.environment.variables.SOPS_AGE_KEY_FILE == k && config.sops.environment.SOPS_AGE_KEY_FILE == k)
      "env=${config.environment.variables.SOPS_AGE_KEY_FILE} sops.env=${config.sops.environment.SOPS_AGE_KEY_FILE} keyFile=${k}";
  check-sops-key-under-home =
    check "sops.age.keyFile under the user's home" (lib.hasPrefix "${config.users.users.${user}.home}/" config.sops.age.keyFile)
      "keyFile=${config.sops.age.keyFile}";
  check-sops-no-ssh-paths =
    check "sops.age.sshKeyPaths and sops.gnupg.sshKeyPaths empty"
      (config.sops.age.sshKeyPaths == [ ] && config.sops.gnupg.sshKeyPaths == [ ])
      "age=${builtins.toJSON config.sops.age.sshKeyPaths} gnupg=${builtins.toJSON config.sops.gnupg.sshKeyPaths}";
  check-nix-extraoptions-include =
    let pat = config.sops.secrets.github_fg_pat_token_nix.path; in
    check "nix.extraOptions !include <github_fg_pat_token_nix path>"
      (lib.hasInfix "!include ${pat}" config.nix.extraOptions)
      "extraOptions=${builtins.toJSON config.nix.extraOptions}, path=${pat}";
  check-github-key-path = checkEq "sops.secrets.github_general_ssh_key.path" config.sops.secrets.github_general_ssh_key.path "/Users/${user}/.ssh/id_github";
  check-github-key-mode = checkEq "sops.secrets.github_general_ssh_key.mode" config.sops.secrets.github_general_ssh_key.mode "0400";

  check-mas-apps-empty = checkEq "homebrew.masApps (mas 7.0.0 guard)" config.homebrew.masApps { };
  check-brew-no-zap = check "homebrew.onActivation.cleanup != zap" (config.homebrew.onActivation.cleanup != "zap") "cleanup is zap";
  check-brew-no-upgrade = checkEq "homebrew.onActivation.upgrade" config.homebrew.onActivation.upgrade false;

  check-browser-no-pkgs =
    check "no firefox/librewolf/chromium in environment.systemPackages" (browserHits == [ ]) "found ${builtins.toJSON browserHits}";

  check-browser-control-bites =
    let wbNames = pnames withBrowser.config; in
    check "control: constants.browser = firefox puts firefox in environment.systemPackages" (builtins.elem "firefox" wbNames) "firefox absent with browser=firefox";

  check-resolved-pkgs-exist =
    check "terminal/fileManager/editor names are real pkgs attrs" (missingPkgs == [ ]) "missing ${builtins.toJSON missingPkgs}";

  check-network-tools-enabled =
    check "network-tools active (control: tcpdump present)" (builtins.elem "tcpdump" sysNames) "tcpdump absent from systemPackages";
  check-no-linux-only-tools =
    check "no Linux-only network tools in systemPackages" (leakedLinuxTools == [ ]) "leaked ${builtins.toJSON leakedLinuxTools}";

  check-mcp-secrets-declared =
    check "every claude-code mcpSecrets[].sopsSecret is a sops.secrets key" (mcpNames != [ ] && missingMcp == [ ])
      "missing ${builtins.toJSON missingMcp} (of ${toString (builtins.length mcpNames)})";

  check-kitty-option-as-alt = checkEq "kitty settings.macos_option_as_alt" hm.programs.kitty.settings.macos_option_as_alt "yes";

  check-assertions =
    let failed = map (a: a.message) (builtins.filter (a: !a.assertion) config.assertions); in
    check "no failing assertions" (failed == [ ]) (builtins.toJSON failed);

  check-dock-no-dangling-nix-apps =
    let bad = danglingDock config dock; in
    check "persistent-apps under Nix Apps / Home Manager Apps match an installed package" (dock != [ ] && bad == [ ])
      "dangling ${builtins.toJSON bad}";
  check-dock-no-disabled-hm-apps =
    let
      disabled = lib.optional (!hm.programs.firefox.enable) "${hmAppsDir}Firefox.app"
        ++ lib.optional (!hm.programs.vscode.enable) "${hmAppsDir}Visual Studio Code.app";
      hits = builtins.filter (e: builtins.elem e dock) disabled;
    in
    check "no persistent-apps entry points at the HM Firefox/VS Code dirs while those programs are disabled" (disabled != [ ] && hits == [ ])
      "entries ${builtins.toJSON hits}";
  check-dock-control-bites =
    let bad = danglingDock config fakeEntries; in
    check "control: dangling HM Firefox/VS Code entries are flagged" (builtins.length bad == 2)
      "flagged ${builtins.toJSON bad}";
  check-dock-autohide = checkEq "system.defaults.dock.autohide" config.system.defaults.dock.autohide true;
  check-finder-extensions = checkEq "system.defaults.finder.AppleShowAllExtensions" config.system.defaults.finder.AppleShowAllExtensions true;

  check-tailscale-cask-present =
    checkHas "homebrew.casks contains tailscale-app" (map (x: if builtins.isString x then x else x.name) config.homebrew.casks) "tailscale-app";
  check-tailscale-daemon-off = checkEq "services.tailscale.enable (nix-darwin daemon)" config.services.tailscale.enable false;
  check-tailscale-flag-consistent =
    check "myconfig.services.tailscale.darwinCaskPresent is true"
      my.services.tailscale.darwinCaskPresent "false although the cask is installed";
  check-tailscale-control-bites =
    checkEq "control: without the cask darwinCaskPresent is false" withoutCask.config.myconfig.services.tailscale.darwinCaskPresent false;

  check-terminal-hm-enabled =
    check "constants.terminal.name resolves to an enabled krit.programs.<name>" (termEnabled config)
      "krit.programs.${termName config}.enable is not true";
  check-terminal-control-bites =
    check "control: terminal.name = alacritty (disabled on this host) is flagged" (!(termEnabled withAlacrittyTerminal.config))
      "alacritty counted as enabled";
}
