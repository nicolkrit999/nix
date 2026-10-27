let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host-darwin.nix flake;

  host = flake.darwinConfigurations.Krits-MacBook-Pro;
  inherit (host) config pkgs;
  my = config.myconfig;
  c = my.constants;
  inherit (c) user;
  hm = config.home-manager.users.${user};

  pnames = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.environment.systemPackages;

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkEq = name: actual: expected:
    check name (actual == expected) "expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  checkHas = name: list: x:
    check name (builtins.elem x list) "${builtins.toJSON x} missing from ${builtins.toJSON list}";

  linuxOnlyTools = [ "ethtool" "iw" "ntopng" "suricata" "ptcpdump" "rsyslog" "wavemon" "sane-airscan" "traceroute" "wireless-tools" ];
  leakedLinuxTools = cfg: builtins.filter (n: builtins.elem n (pnames cfg)) linuxOnlyTools;

  browserPnames = [ "firefox" "librewolf" "chromium" ];
  browserHits = cfg: builtins.filter (n: builtins.elem n (pnames cfg)) browserPnames;

  fxBrowserDefault = fx.mkDarwin { paths = [ (fx.src + "/modules/darwin/toplevel/home-packages-darwin.nix") ]; };
  fxBrowserOptOut = fxBrowserDefault.extendModules { modules = [{ myconfig.constants.browser = ""; }]; };

  fxNetwork = fx.mkDarwin {
    paths = [ (fx.src + "/users/krit/common/programs/network-tools.nix") ];
    modules = [{ myconfig.krit.services.network-tools.enable = true; }];
  };

  mcpPaths = [
    (fx.src + "/modules/common/programs/claude-code.nix")
    (fx.src + "/users/krit/common/programs/claude-code/claude-code-personal.nix")
    (fx.src + "/users/krit/common/toplevel/sops-secrets.nix")
  ];
  mcpOn = { myconfig.krit.commonSopsSecrets.enable = true; myconfig.krit.programs.claude-code-personal.enable = true; };
  fxMcp = fx.mkDarwin { paths = mcpPaths; modules = [ mcpOn ]; };
  fxMcpOverride = fx.mkDarwin {
    paths = mcpPaths;
    modules = [ mcpOn { myconfig.krit.programs.claude-code-personal.mcpSecrets = [{ sopsSecret = "fixture_only_secret"; }]; } ];
  };
  fxMcpOff = fx.mkDarwin {
    paths = mcpPaths;
    modules = [{ myconfig.krit.commonSopsSecrets.enable = true; }];
  };
  mcpNames = map (s: s.sopsSecret) fxMcp.config.myconfig.krit.programs.claude-code-personal.mcpSecrets;
  missingMcp = builtins.filter (n: !(fxMcp.config.sops.secrets ? ${n})) mcpNames;

  fxTailscale = fx.mkDarwin { paths = [ (fx.src + "/modules/common/services/tailscale.nix") ]; };
  fxTailscaleCask = fxTailscale.extendModules { modules = [{ homebrew.casks = [ "tailscale-app" ]; }]; };

  kittyPaths = [
    (fx.src + "/modules/darwin/toplevel/stylix-darwin.nix")
    (fx.src + "/modules/common/programs/kitty.nix")
    (fx.src + "/users/krit/common/programs/terminal-emulators/kitty.nix")
  ];
  fxKittyOff = fx.mkDarwin { paths = kittyPaths; modules = [{ myconfig.stylix.enable = false; }]; };
  fxKitty = fxKittyOff.extendModules { modules = [{ myconfig.krit.programs.kitty.enable = true; }]; };

  translatedEditor = if c.editor == "nvim" then "neovim" else c.editor;
  resolvedNames = [ c.terminal.name c.fileManager translatedEditor ];
  missingPkgs = builtins.filter (n: !(builtins.hasAttr n pkgs)) resolvedNames;

  withBothProviders = host.extendModules {
    modules = [ ({ lib, ... }: { homebrew.casks = lib.mkForce [ "tailscale-app" ]; services.tailscale.enable = lib.mkForce true; }) ];
  };
  doubleProvider = cfg: cfg.myconfig.services.tailscale.darwinCaskPresent && cfg.services.tailscale.enable;
  withUnknownTerminal = host.extendModules {
    modules = [ ({ lib, ... }: { myconfig.constants.terminal.name = lib.mkForce "no-such-terminal-xyz"; }) ];
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
  fakeEntries = dock ++ [ "${hmAppsDir}No Such Test App.app" "${nixAppsDir}No Such Test App.app" ];

  termName = cfg: cfg.myconfig.constants.terminal.name;
  termEnabled = cfg: cfg.myconfig.krit.programs.${termName cfg}.enable or false;
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

  check-browser-optout-no-pkgs =
    check "fixture: constants.browser = \"\" puts no firefox/librewolf/chromium in systemPackages" (browserHits fxBrowserOptOut.config == [ ])
      "found ${builtins.toJSON (browserHits fxBrowserOptOut.config)}";
  check-browser-control-bites =
    check "control: fixture with default constants.browser puts firefox in systemPackages" (builtins.elem "firefox" (browserHits fxBrowserDefault.config))
      "firefox absent with the default browser";

  check-resolved-pkgs-exist =
    check "terminal/fileManager/editor names are real pkgs attrs" (missingPkgs == [ ]) "missing ${builtins.toJSON missingPkgs}";

  check-network-tools-enabled =
    check "fixture: network-tools active (control: tcpdump present)" (builtins.elem "tcpdump" (pnames fxNetwork.config)) "tcpdump absent from systemPackages";
  check-no-linux-only-tools =
    check "fixture: no Linux-only network tools in systemPackages" (leakedLinuxTools fxNetwork.config == [ ])
      "leaked ${builtins.toJSON (leakedLinuxTools fxNetwork.config)}";

  check-mcp-secrets-declared =
    check "fixture: every claude-code mcpSecrets[].sopsSecret is a sops.secrets key" (mcpNames != [ ] && missingMcp == [ ])
      "missing ${builtins.toJSON missingMcp} (of ${toString (builtins.length mcpNames)})";
  check-mcp-secrets-follow-list =
    let sec = fxMcpOverride.config.sops.secrets; in
    check "control: overriding mcpSecrets replaces the declared secrets"
      (sec ? fixture_only_secret && !(sec ? ${builtins.head mcpNames}))
      "secrets ${builtins.toJSON (builtins.attrNames sec)}";
  check-mcp-secrets-off-control =
    check "control: claude-code-personal disabled declares no mcp secret"
      (!(fxMcpOff.config.sops.secrets ? ${builtins.head mcpNames}))
      "${builtins.head mcpNames} declared while disabled";

  check-kitty-option-as-alt = checkEq "fixture: kitty settings.macos_option_as_alt" (fx.hmOf fxKitty.config).programs.kitty.settings.macos_option_as_alt "yes";
  check-kitty-option-as-alt-control =
    check "control: kitty disabled sets no macos_option_as_alt"
      (!((fx.hmOf fxKittyOff.config).programs.kitty.settings ? macos_option_as_alt))
      "macos_option_as_alt set while kitty is disabled";

  check-assertions =
    let failed = map (a: a.message) (builtins.filter (a: !a.assertion) config.assertions); in
    check "no failing assertions" (failed == [ ]) (builtins.toJSON failed);

  check-dock-no-dangling-nix-apps =
    let bad = danglingDock config dock; in
    check "persistent-apps under Nix Apps / Home Manager Apps match an installed package" (bad == [ ])
      "dangling ${builtins.toJSON bad}";
  check-dock-control-bites =
    let bad = danglingDock config fakeEntries; in
    check "control: injected dangling HM and Nix Apps entries are both flagged" (builtins.length bad == 2)
      "flagged ${builtins.toJSON bad}";
  check-dock-autohide = checkEq "system.defaults.dock.autohide" config.system.defaults.dock.autohide true;
  check-finder-extensions = checkEq "system.defaults.finder.AppleShowAllExtensions" config.system.defaults.finder.AppleShowAllExtensions true;

  check-tailscale-no-double-provider =
    check "not both the tailscale cask and the nix-darwin tailscale daemon" (!(doubleProvider config))
      "darwinCaskPresent=${builtins.toJSON my.services.tailscale.darwinCaskPresent} daemon=${builtins.toJSON config.services.tailscale.enable}";
  check-tailscale-double-provider-control =
    check "control: cask plus daemon is flagged as double provider" (doubleProvider withBothProviders.config) "not flagged";
  check-tailscale-flag-cask =
    check "fixture: darwinCaskPresent is true with the tailscale-app cask" fxTailscaleCask.config.myconfig.services.tailscale.darwinCaskPresent
      "false although the cask is installed";
  check-tailscale-flag-no-cask =
    checkEq "control: fixture without the cask has darwinCaskPresent false" fxTailscale.config.myconfig.services.tailscale.darwinCaskPresent false;

  check-terminal-hm-enabled =
    check "constants.terminal.name resolves to an enabled krit.programs.<name>" (termEnabled config)
      "krit.programs.${termName config}.enable is not true";
  check-terminal-control-bites =
    check "control: an unknown terminal.name is flagged" (!(termEnabled withUnknownTerminal.config))
      "unknown terminal counted as enabled";
}
