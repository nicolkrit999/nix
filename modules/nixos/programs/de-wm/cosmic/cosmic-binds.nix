{ delib
, lib
, pkgs
, ...
}:
let
  windowBinds = [
    { key = "Super+M"; variant = "Fullscreen"; name = "Toggle fullscreen"; }
    { key = "Super+Shift+F"; variant = "Fullscreen"; name = "Toggle fullscreen"; }
    { key = "Super+Alt+A"; variant = "Maximize"; name = "Toggle maximize"; }
    { key = "Super+Shift+C"; variant = "Close"; name = "Close window"; }
    { key = "Super+Shift+M"; variant = "Minimize"; name = "Minimize window"; }
  ];

  systemBinds = [
    { key = "Super+Delete"; variant = "LockScreen"; name = "Lock session"; }
    { key = "Super+Shift+Delete"; variant = "LogOut"; name = "Log out"; }
  ];

  fixedKeys = [
    "Super+Return"
    "Super+B"
    "Super+C"
    "Super+F"
    "Super+Ctrl+3"
    "Super+Ctrl+4"
    "Super+A"
    "Super+V"
    "Super+period"
  ] ++ map (b: b.key) (windowBinds ++ systemBinds);

  normKey = key:
    let p = lib.splitString "+" (lib.toLower key);
    in lib.concatStringsSep "+" (lib.sort (a: b: a < b) (lib.init p) ++ [ (lib.last p) ]);

  mkDisable = key: {
    inherit key;
    action = {
      __type = "enum";
      variant = "Disable";
    };
  };
in
delib.module {
  name = "programs.cosmic";

  nixos.ifEnabled =
    { cfg, ... }:
    let
      activeKeys = map normKey (fixedKeys ++ map (b: b.key) (lib.attrValues cfg.extraBinds));
    in
    {
      assertions = [
        {
          assertion = lib.all (k: builtins.match "[A-Za-z0-9+_]+" k != null) cfg.disabledDefaults;
          message = "programs.cosmic.disabledDefaults: entries must be non-empty strings of letters, digits, + and _";
        }
        {
          assertion = lib.all (k: !(builtins.elem (normKey k) activeKeys)) cfg.disabledDefaults;
          message = "programs.cosmic.disabledDefaults: an entry equals a key bound by this module or extraBinds, it would disable that bind";
        }
      ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , parent
    , ...
    }:
    let
      vicinaeEnabled = parent.vicinae.enable or true;
      termApps = myconfig.constants.terminalApps;
      inTerminal = app: "${myconfig.constants.terminal.name} -e ${app}";
      wrap = app: if builtins.elem app termApps then inTerminal app else app;

      spawn = command: {
        __type = "enum";
        variant = "Spawn";
        value = [ command ];
      };
      mkBind = { key, command, name ? null, ... }: {
        inherit key;
        description =
          if name == null then null else {
            __type = "optional";
            value = name;
          };
        action = spawn command;
      };

      screenshotDir = myconfig.constants.screenshots;
      screenshotFull = pkgs.writeShellScript "cosmic-screenshot-full" ''
        dir="${screenshotDir}"
        mkdir -p "$dir"
        ${lib.getExe pkgs.grim} "$dir/Screenshot_$(date +%F_%H-%M-%S).png"
      '';

      mkWindowBind = { key, variant, name }: {
        inherit key;
        description = {
          __type = "optional";
          value = name;
        };
        action = {
          __type = "enum";
          inherit variant;
        };
      };

      mkSystemBind = { key, variant, name }: {
        inherit key;
        description = {
          __type = "optional";
          value = name;
        };
        action = {
          __type = "enum";
          variant = "System";
          value = [{ __type = "enum"; inherit variant; }];
        };
      };

      baseBinds = {
        "launch-terminal" = {
          name = "Launch ${myconfig.constants.terminal.name}";
          key = "Super+Return";
          command = myconfig.constants.terminal.name;
        };
        "launch-browser" = {
          name = "Launch ${myconfig.constants.browser}";
          key = "Super+B";
          command = myconfig.constants.browser;
        };
        "launch-editor" = {
          name = "Launch ${myconfig.constants.editor}";
          key = "Super+C";
          command = wrap myconfig.constants.editor;
        };
        "launch-filemanager" = {
          name = "Launch ${myconfig.constants.fileManager}";
          key = "Super+F";
          command = wrap myconfig.constants.fileManager;
        };
      };

      screenshotBinds = {
        "screenshot-full" = {
          name = "Screenshot: full screen";
          key = "Super+Ctrl+3";
          command = "${screenshotFull}";
        };
        "screenshot-select" = {
          name = "Screenshot: select area or window";
          key = "Super+Ctrl+4";
          command = lib.getExe' pkgs.cosmic-screenshot "cosmic-screenshot";
        };
      };

      vicinaeBinds = lib.optionalAttrs vicinaeEnabled {
        "vicinae-toggle" = {
          name = "Vicinae: Application Launcher";
          key = "Super+A";
          command = "vicinae toggle";
        };
        "vicinae-clipboard" = {
          name = "Vicinae: Clipboard";
          key = "Super+V";
          command = "vicinae vicinae://launch/clipboard/history";
        };
        "vicinae-emoji" = {
          name = "Vicinae: Emoji Picker";
          key = "Super+period";
          command = "vicinae vicinae://launch/core/search-emojis";
        };
      };
    in
    {
      wayland.desktopManager.cosmic = {
        enable = true;
        shortcuts =
          map mkBind (lib.attrValues (baseBinds // screenshotBinds // vicinaeBinds // cfg.extraBinds))
          ++ map mkWindowBind windowBinds
          ++ map mkSystemBind systemBinds
          ++ map mkDisable cfg.disabledDefaults;
      };
    };
}
