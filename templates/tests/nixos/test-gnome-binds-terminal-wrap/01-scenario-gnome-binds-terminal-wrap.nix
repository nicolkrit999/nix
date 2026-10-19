let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostNames = [
    "nixos-desktop"
    "nixos-laptop"
  ];
  roles = {
    "Launch File Manager" = "fileManager";
    "Launch editor" = "editor";
  };

  variantsOf =
    sys: { base = sys.config; } // lib.mapAttrs (_: s: s.configuration) sys.config.specialisation;
  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
  gnomeOn = c: c.myconfig.programs.gnome.enable;

  bindsOf =
    c:
    lib.filter (b: b ? name) (
      lib.mapAttrsToList (_: v: v) (
        lib.filterAttrs (k: _: lib.hasInfix "custom-keybindings/custom" k) (hmOf c).dconf.settings
      )
    );
  commandOf =
    c: bindName:
    let
      m = lib.filter (b: b.name == bindName) (bindsOf c);
    in
    if m == [ ] then null else (lib.head m).command;

  expected =
    { terminal, terminalApps }:
    app: if lib.elem app terminalApps then "${terminal} -e ${app}" else app;
  expectedOf =
    c:
    expected {
      terminal = c.myconfig.constants.terminal.name;
      terminalApps = c.myconfig.constants.terminalApps;
    };

  roleChecks =
    label: c:
    lib.mapAttrsToList
      (
        bindName: constant:
        let
          app = c.myconfig.constants.${constant};
          want = expectedOf c app;
          got = commandOf c bindName;
        in
        {
          label = "${label}: ${bindName} (${constant}=${app})";
          result =
            if got == want then "ok" else "FAIL: command is ${toString got}, expected ${want}";
        }
      )
      roles;

  hostReport =
    h:
    let
      vs = variantsOf flake.nixosConfigurations.${h};
    in
    lib.concatLists (
      lib.mapAttrsToList (n: c: lib.optionals (gnomeOn c) (roleChecks "${h}/${n}" c)) vs
    );

  gnomeVariants = lib.concatMap
    (
      h: lib.attrNames (lib.filterAttrs (_: gnomeOn) (variantsOf flake.nixosConfigurations.${h}))
    )
    hostNames;

  ctlHost = "nixos-desktop";
  ctl = flake.nixosConfigurations.${ctlHost};
  ctlTerminal = ctl.config.myconfig.constants.terminal.name;
  twin = constants: (ctl.extendModules { modules = [{ myconfig.constants = constants; }]; }).config;
  force = lib.mkForce;

  twinCheck =
    label: constants: bindName: want:
    let
      c = twin constants;
      got = commandOf c bindName;
    in
    {
      inherit label;
      result =
        if !(gnomeOn c) then
          "FAIL: twin lost GNOME, control is vacuous"
        else if got == want then
          "ok"
        else
          "FAIL: command is ${toString got}, expected ${want}";
    };

  planted = expected {
    terminal = "kitty";
    terminalApps = [ "yazi" ];
  };

  controls = [
    (twinCheck "control: GUI file manager is launched bare" { fileManager = force "nautilus"; } "Launch File Manager" "nautilus")
    (twinCheck "control: TUI editor is wrapped in the terminal" { editor = force "hx"; } "Launch editor" "${ctlTerminal} -e hx")
    (twinCheck "control: TUI role is launched bare once it leaves terminalApps"
      {
        fileManager = force "yazi";
        terminalApps = force [ ];
      } "Launch File Manager" "yazi")
    (twinCheck "control: wrapper uses constants.terminal.name"
      {
        terminal.name = force "wezterm";
        fileManager = force "yazi";
      } "Launch File Manager" "wezterm -e yazi")
    {
      label = "control: expectation rejects a bare TUI command";
      result = if planted "yazi" == "yazi" then "FAIL: planted bare yazi accepted" else "ok";
    }
    {
      label = "control: expectation rejects a wrapped GUI command";
      result = if planted "nautilus" == "kitty -e nautilus" then "FAIL: planted wrapped GUI accepted" else "ok";
    }
  ];

  render = rs: lib.concatMapStrings (r: "${r.label}\t${r.result}\n") rs;
in
{
  report = render (
    lib.concatMap hostReport hostNames
    ++ [
      {
        label = "at least one GNOME variant evaluated";
        result =
          if gnomeVariants != [ ] then
            "ok"
          else
            "FAIL: no variant enables GNOME, every positive check would be vacuous";
      }
    ]
  );
  control = render controls;
}
