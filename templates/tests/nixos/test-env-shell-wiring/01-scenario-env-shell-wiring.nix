let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  sys = fx.mkNixos [{
    myconfig.constants = {
      shell = "zsh";
      editor = "kate";
      browser = "fixture-browser";
      terminal.name = "fixture-terminal";
    };
  }];
  baseCfg = sys.config;
  user = baseCfg.myconfig.constants.user;
  twin = mods: (sys.extendModules { modules = mods; }).config;
  ov = lib.mkOverride 10;

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";

  shells = {
    bash = "bash-interactive";
    fish = "fish";
    zsh = "zsh";
  };
  shellTwin = s: twin [{ myconfig.constants.shell = ov s; }];
  shellChecks = lib.concatMapAttrs
    (s: pname:
      let c = shellTwin s; in {
        "shell ${s}: users.defaultUserShell is ${pname}" = eq "defaultUserShell" c.users.defaultUserShell.pname pname;
        "shell ${s}: users.users.${user}.shell is ${pname}" = eq "user shell" c.users.users.${user}.shell.pname pname;
        "shell ${s}: programs.zsh.enable follows" = eq "programs.zsh.enable" c.programs.zsh.enable (s == "zsh");
        "shell ${s}: programs.fish.enable follows" = eq "programs.fish.enable" c.programs.fish.enable (s == "fish");
        "shell ${s}: shell package is in systemPackages" =
          yes "no ${pname} in environment.systemPackages"
            (builtins.elem pname (map (p: p.pname or "") c.environment.systemPackages));
      })
    shells;

  baseShell = baseCfg.myconfig.constants.shell;
  baseChecks = {
    "fixture: user shell is the default user shell" =
      eq "shell drv" baseCfg.users.users.${user}.shell.outPath baseCfg.users.defaultUserShell.outPath;
    "fixture: shell package matches constants.shell" =
      eq "pname" baseCfg.users.defaultUserShell.pname shells.${baseShell};
    "fixture: programs.zsh.enable matches constants.shell" =
      eq "programs.zsh.enable" baseCfg.programs.zsh.enable (baseShell == "zsh");
    "fixture: programs.fish.enable matches constants.shell" =
      eq "programs.fish.enable" baseCfg.programs.fish.enable (baseShell == "fish");
    "control: the three shells map to three distinct packages" =
      eq "distinct pnames" (lib.unique (lib.attrValues shells)) (lib.attrValues shells);
  };

  envOf = c: c.environment.sessionVariables;
  editors = {
    code = "code --wait";
    gedit = "gedit --wait";
    kate = "kate --block";
    nano = "nano";
    neovim = "nvim";
    nvim = "nvim";
    subl = "subl --wait";
    vim = "vim";
    vscode = "code --wait";
    some-unlisted-editor = "some-unlisted-editor";
  };
  baseEditor = baseCfg.myconfig.constants.editor;
  wantEditor = editors.${baseEditor} or baseEditor;
  editorIs = want: (envOf baseCfg).EDITOR == want;
  editorChecks = lib.mapAttrs'
    (e: flag: lib.nameValuePair "editor ${e}: EDITOR is ${flag}"
      (eq "EDITOR" (envOf (twin [{ myconfig.constants.editor = ov e; }])).EDITOR flag))
    editors;

  roleTwin = twin [{
    myconfig.constants = {
      browser = ov "browser-twin";
      terminal.name = ov "terminal-twin";
    };
  }];
  serverTwin = twin [{
    myconfig = {
      host.isServer = ov true;
      constants = {
        browser = ov "browser-twin";
        terminal.name = ov "terminal-twin";
      };
    };
  }];
  desktopTwin = twin [{
    myconfig = {
      host.isServer = ov false;
      constants = {
        browser = ov "browser-twin";
        terminal.name = ov "terminal-twin";
      };
    };
  }];
  roleChecks = {
    "env: BROWSER follows constants.browser (desktop)" = eq "BROWSER" (envOf desktopTwin).BROWSER "browser-twin";
    "env: TERMINAL follows constants.terminal.name (desktop)" = eq "TERMINAL" (envOf desktopTwin).TERMINAL "terminal-twin";
    "env: server host exports no BROWSER" = yes "BROWSER set on a server" (!(envOf serverTwin ? BROWSER));
    "env: server host exports no TERMINAL" = yes "TERMINAL set on a server" (!(envOf serverTwin ? TERMINAL));
    "env: server host still exports EDITOR" = yes "EDITOR missing on a server" (envOf serverTwin ? EDITOR);
    "control: role twin differs from the fixture values" =
      yes "twin equals base" (!(roleTwin.environment.sessionVariables ? BROWSER) || roleTwin.environment.sessionVariables.BROWSER != baseCfg.myconfig.constants.browser);
  };
  envChecks = {
    "env: XDG_BIN_HOME is exported" = eq "XDG_BIN_HOME" (envOf baseCfg).XDG_BIN_HOME "$HOME/.local/bin";
    "env: ~/.local/bin is on PATH" = eq "localBinInPath" baseCfg.environment.localBinInPath true;
    "fixture: BROWSER/TERMINAL, when exported, equal the constants" =
      yes "session vars diverge from constants"
        ((!(envOf baseCfg ? BROWSER) || (envOf baseCfg).BROWSER == baseCfg.myconfig.constants.browser)
          && (!(envOf baseCfg ? TERMINAL) || (envOf baseCfg).TERMINAL == baseCfg.myconfig.constants.terminal.name));
    "fixture: EDITOR is the mapping of constants.editor" = eq "EDITOR" (envOf baseCfg).EDITOR wantEditor;
    "control: the EDITOR predicate rejects a wrong value" = eq "editorIs (wrong value)" (editorIs "${wantEditor}-wrong") false;
  };

  hmOf = c: c.home-manager.users.${user};
  ext = c: c.home-manager.backupFileExtension;
  removeEntry = c: (hmOf c).home.activation.removeExistingConfigs;
  backupCoherent = c: lib.hasInfix "mimeapps.list.${ext c}" (removeEntry c).data;
  extTwin = twin [{ home-manager.backupFileExtension = ov "other-ext"; }];
  hmChecks = {
    "home-manager: backupFileExtension is set" = yes "empty backup extension" (ext baseCfg != null && ext baseCfg != "");
    "home-manager: removeExistingConfigs runs before checkLinkTargets" =
      yes "before = ${builtins.toJSON (removeEntry baseCfg).before}" (builtins.elem "checkLinkTargets" (removeEntry baseCfg).before);
    "home-manager: removeExistingConfigs deletes the backup of the configured extension" =
      yes "script does not mention mimeapps.list.${ext baseCfg}" (backupCoherent baseCfg);
  };
  hmTwinChecks = {
    "control: a different backup extension breaks the coherence predicate" =
      eq "backupCoherent (twin)" (backupCoherent extTwin) false;
  };

  initOf = s: c:
    let p = (hmOf c).programs; in
    if s == "bash" then p.bash.initExtra
    else if s == "zsh" then p.zsh.initContent
    else p.fish.interactiveShellInit;
  wrapMarker = "# SETUID WRAPPERS FIRST ON PATH";
  tmuxBlocks = {
    bash = ''
      # TMUX AUTOSTART
      if command -v tmux > /dev/null && [ -z "$TMUX" ] && [ -z "$NVIM" ] && [ -z "$HERDR_PANE_ID" ] && [ -z "$HC_TERMINAL_ID" ] && [ -n "$DISPLAY" ]; then
        tmux new-session -A -s main
      fi
    '';
    zsh = ''
      # TMUX AUTOSTART (Only in GUI)
      if command -v tmux > /dev/null && [ -z "$TMUX" ] && [ -z "$NVIM" ] && [ -z "$HERDR_PANE_ID" ] && [ -z "$HC_TERMINAL_ID" ] && [ -n "$DISPLAY" ]; then
        tmux new-session -A -s main
      fi
    '';
    fish = ''
      # TMUX AUTOSTART (GUI only on NixOS, always on Darwin)
      if command -v tmux > /dev/null; and not set -q TMUX; and not set -q NVIM; and not set -q HERDR_PANE_ID; and not set -q HC_TERMINAL_ID; and set -q DISPLAY
        tmux new-session -A -s main
      end
    '';
  };
  wrapLines = {
    bash = ''PATH="/run/wrappers/bin''${_wrap_path:+:''${_wrap_path%:}}"'';
    zsh = ''path=(/run/wrappers/bin ''${path:#/run/wrappers/bin})'';
    fish = ''set -gx PATH /run/wrappers/bin (string match -v -- /run/wrappers/bin $PATH)'';
  };
  tmuxMarker = "# TMUX AUTOSTART";
  beforeTmux = txt: builtins.elemAt (lib.splitString tmuxMarker txt) 0;
  hasWrapBeforeTmux = s: txt:
    let pre = beforeTmux txt; in
    lib.hasInfix wrapMarker pre && lib.hasInfix wrapLines.${s} pre && lib.hasInfix "-d /run/wrappers/bin" pre;
  hasTmuxBlock = s: txt: lib.hasInfix tmuxBlocks.${s} txt && !(lib.hasInfix "wrappers" tmuxBlocks.${s});
  wrapChecks = lib.concatMapAttrs
    (s: _:
      let txt = initOf s (shellTwin s); in {
        "path: ${s} init puts /run/wrappers/bin first when the dir exists" =
          yes "${s} init lacks the guarded wrappers-first snippet" (lib.hasInfix wrapMarker txt && lib.hasInfix wrapLines.${s} txt);
        "path: ${s} wrappers snippet sits before and outside the tmux autostart block" =
          yes "${s} snippet not ahead of the tmux block" (hasWrapBeforeTmux s txt);
        "tmux: ${s} autostart block is unchanged (HERDR_PANE_ID / HC_TERMINAL_ID / NVIM / DISPLAY guards)" =
          yes "${s} tmux autostart block differs from the recorded one" (hasTmuxBlock s txt);
      })
    shells // {
    "control: wrappers predicate fails on init text without the snippet" =
      eq "hasWrapBeforeTmux (snippet removed)" (hasWrapBeforeTmux "bash" (lib.replaceStrings [ wrapMarker ] [ "# X" ] (initOf "bash" (shellTwin "bash")))) false;
    "control: tmux predicate fails on a block with the herdr guard removed" =
      eq "hasTmuxBlock (HERDR guard removed)" (hasTmuxBlock "zsh" (lib.replaceStrings [ " && [ -z \"$HERDR_PANE_ID\" ]" ] [ "" ] (initOf "zsh" (shellTwin "zsh")))) false;
  };

  btTwin = on: x: twin [{ myconfig.bluetooth.enable = ov on; myconfig.bluetooth.autoEnableOnBoot = ov x; }];
  zrTwin = on: p: twin [{ myconfig.zram.enable = ov on; myconfig.zram.zramPercent = ov p; }];
  hwChecks = {
    "bluetooth: autoEnableOnBoot=true powers on at boot" = eq "powerOnBoot" (btTwin true true).hardware.bluetooth.powerOnBoot true;
    "bluetooth: autoEnableOnBoot=false does not power on at boot" = eq "powerOnBoot" (btTwin true false).hardware.bluetooth.powerOnBoot false;
    "bluetooth: enabled module enables hardware.bluetooth" = eq "hardware.bluetooth.enable" (btTwin true true).hardware.bluetooth.enable true;
    "bluetooth: enabled module enables blueman" = eq "services.blueman.enable" (btTwin true true).services.blueman.enable true;
    "zram: enabled module enables zramSwap" = eq "zramSwap.enable" (zrTwin true 37).zramSwap.enable true;
    "zram: zramPercent 37 reaches memoryPercent" = eq "memoryPercent" (zrTwin true 37).zramSwap.memoryPercent 37;
    "zram: zramPercent 61 reaches memoryPercent" = eq "memoryPercent" (zrTwin true 61).zramSwap.memoryPercent 61;
    "control: disabled zram module leaves zramSwap off" = eq "zramSwap.enable" (zrTwin false 37).zramSwap.enable false;
  };

  fixtureChecks = baseChecks // envChecks // hmChecks
    // { "control: check helper detects mismatch" = yes "helper broken" (lib.hasPrefix "FAIL" (eq "x" 1 2)); };
  twinChecks = shellChecks // wrapChecks // editorChecks // roleChecks // hmTwinChecks // hwChecks;
  checks = fixtureChecks // twinChecks;

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
