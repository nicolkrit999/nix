let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  host = flake.darwinConfigurations.Krits-MacBook-Pro;
  config = host.config;
  c = config.myconfig.constants;
  user = c.user;
  hmOf = cfg: cfg.home-manager.users.${user};
  hm = hmOf config;

  ext = mod: (host.extendModules { modules = [ ({ lib, ... }: mod lib) ]; }).config;

  lightCfg = ext (lib: { myconfig.constants.theme.polarity = lib.mkForce "light"; });
  stylixOffCfg = ext (lib: { myconfig.stylix.enable = lib.mkForce false; });
  bareTargetsCfg = ext (lib: { myconfig.stylix.targets.bat.enable = lib.mkForce false; });
  zshCfg = ext (lib: { myconfig.constants.shell = lib.mkForce "zsh"; });
  bashCfg = ext (lib: { myconfig.constants.shell = lib.mkForce "bash"; });
  helixCfg = ext (lib: { myconfig.constants.editor = lib.mkForce "helix"; });
  alacrittyCfg = ext (lib: { myconfig.constants.terminal.name = lib.mkForce "alacritty"; });
  bogusCfg = ext (lib: { myconfig.constants.fileManager = lib.mkForce "no-such-file-manager-xyz"; });

  pnames = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.environment.systemPackages;

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkEq = name: actual: expected:
    check name (actual == expected) "expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  catppuccinOwned = [ "bat" "lazygit" "starship" "tmux" ];
  alwaysOff = [ "neovim" "rofi" "gtksourceview" ];
in
{
  check-stylix-enabled = checkEq "stylix.enable (myconfig.stylix.enable default)" config.stylix.enable true;
  check-stylix-off-control = checkEq "control: myconfig.stylix.enable = false turns stylix.enable off" stylixOffCfg.stylix.enable false;
  check-stylix-polarity = checkEq "stylix.polarity follows constants.theme.polarity" config.stylix.polarity c.theme.polarity;
  check-stylix-scheme =
    check "stylix.base16Scheme is <base16-schemes>/share/themes/<base16Theme>.yaml"
      (lib.hasSuffix "/share/themes/${c.theme.base16Theme}.yaml" (toString config.stylix.base16Scheme))
      "scheme=${toString config.stylix.base16Scheme}";
  check-stylix-fonts =
    let f = config.stylix.fonts; in
    check "stylix monospace/sansSerif/serif all JetBrainsMono Nerd Font family"
      (f.monospace.name == "JetBrainsMono Nerd Font" && lib.hasPrefix "JetBrainsMono Nerd Font" f.sansSerif.name && lib.hasPrefix "JetBrainsMono Nerd Font" f.serif.name)
      "mono=${f.monospace.name} sans=${f.sansSerif.name} serif=${f.serif.name}";
  check-stylix-font-sizes =
    let s = config.stylix.fonts.sizes; in
    check "stylix font sizes terminal 14 / desktop 12 / popups 10" (s.terminal == 14 && s.desktop == 12 && s.popups == 10)
      "sizes=${builtins.toJSON { inherit (s) terminal desktop popups; }}";

  check-hm-targets-always-off =
    let on = builtins.filter (t: hm.stylix.targets.${t}.enable) alwaysOff; in
    check "HM stylix.targets neovim/rofi/gtksourceview are disabled" (on == [ ]) "enabled: ${builtins.toJSON on}";
  check-hm-targets-follow-catppuccin =
    let wrong = builtins.filter (t: hm.stylix.targets.${t}.enable != !c.theme.catppuccin) catppuccinOwned; in
    check "HM stylix bat/lazygit/starship/tmux targets == !constants.theme.catppuccin" (wrong == [ ])
      "mismatch: ${builtins.toJSON wrong} (catppuccin=${builtins.toJSON c.theme.catppuccin})";
  check-hm-targets-override-control =
    checkEq "control: myconfig.stylix.targets.bat.enable = false overrides the default" (hmOf bareTargetsCfg).stylix.targets.bat.enable false;

  check-dark-style-dark = checkEq "NSGlobalDomain.AppleInterfaceStyle for polarity dark" config.system.defaults.NSGlobalDomain.AppleInterfaceStyle "Dark";
  check-light-style-null =
    check "control: polarity light leaves AppleInterfaceStyle unset (null)" (lightCfg.system.defaults.NSGlobalDomain.AppleInterfaceStyle == null)
      "got ${builtins.toJSON lightCfg.system.defaults.NSGlobalDomain.AppleInterfaceStyle}";
  check-polarity-is-dark = checkEq "this host's polarity (guards the dark branch above)" c.theme.polarity "dark";

  check-touchid =
    let p = config.security.pam.services.sudo_local; in
    check "sudo_local touchIdAuth + reattach" (p.touchIdAuth && p.reattach) "touchIdAuth=${builtins.toJSON p.touchIdAuth} reattach=${builtins.toJSON p.reattach}";
  check-allow-unfree = checkEq "nixpkgs.config.allowUnfree" config.nixpkgs.config.allowUnfree true;
  check-state-version = checkEq "system.stateVersion == constants.darwinStateVersion" config.system.stateVersion c.darwinStateVersion;
  check-hostnames =
    check "networking.hostName == computerName == constants.hostname"
      (config.networking.hostName == c.hostname && config.networking.computerName == c.hostname)
      "hostName=${config.networking.hostName} computerName=${config.networking.computerName} constant=${c.hostname}";
  check-hm-backup-ext = checkEq "home-manager.backupFileExtension" config.home-manager.backupFileExtension "hm-backup";
  check-login-shells =
    check "programs.zsh and programs.fish enabled system-wide" (config.programs.zsh.enable && config.programs.fish.enable) "a login shell is disabled";
  check-nix-index = checkEq "programs.nix-index.enable (nix-index-database darwin module imported)" config.programs.nix-index.enable true;
  check-nix-path = checkEq "nix.nixPath" config.nix.nixPath [ "nixpkgs=flake:nixpkgs" ];
  check-auto-optimise = checkEq "nix.settings.auto-optimise-store" config.nix.settings.auto-optimise-store true;

  check-shell-fish = checkEq "constants.shell fish -> user shell pname" config.users.users.${user}.shell.pname "fish";
  check-shell-zsh = checkEq "control: constants.shell zsh -> user shell pname" zshCfg.users.users.${user}.shell.pname "zsh";
  check-shell-bash = checkEq "control: constants.shell bash -> bashInteractive" bashCfg.users.users.${user}.shell.pname "bash-interactive";

  check-role-enabled-program-not-doubled =
    check "terminal kitty is an enabled program, so home-packages adds no system kitty"
      (c.terminal.name == "kitty" && !(builtins.elem "kitty" (pnames config)))
      "terminal=${c.terminal.name}, systemPackages has kitty: ${builtins.toJSON (builtins.elem "kitty" (pnames config))}";
  check-role-terminal-control =
    check "control: a terminal whose program is disabled (alacritty) lands in systemPackages"
      (builtins.elem "alacritty" (pnames alacrittyCfg)) "alacritty missing";
  check-role-editor-control =
    check "control: constants.editor = helix installs the helix package" (builtins.elem "helix" (pnames helixCfg)) "helix missing";
  check-role-editor-translation =
    check "editor nvim is translated to pkgs.neovim (no 'nvim' attr warning)"
      (c.editor == "nvim" && !(builtins.any (w: lib.hasInfix "editor = \"nvim\"" w) config.warnings))
      "editor=${c.editor}";
  check-role-no-warnings =
    check "no home-packages warning on the real host (empty browser is a silent opt-out)"
      (c.browser == "" && builtins.filter (w: lib.hasPrefix "home-packages:" w) config.warnings == [ ])
      "browser=${builtins.toJSON c.browser}";
  check-role-warning-control =
    check "control: a role naming a non-package emits the home-packages warning"
      (builtins.any (w: lib.hasInfix "fileManager = \"no-such-file-manager-xyz\"" w) bogusCfg.warnings)
      "warnings=${builtins.toJSON bogusCfg.warnings}";
}
