let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  fx = import ../../lib/fixture-host.nix flake;

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

  force = lib.mkForce;
  fixture = fx.mkNixos [
    {
      myconfig.programs.gnome.enable = true;
      myconfig.constants = {
        terminal.name = "kitty";
        fileManager = "yazi";
        editor = "gedit";
        terminalApps = [
          "yazi"
          "hx"
        ];
      };
    }
  ];
  twin = constants: (fixture.extendModules { modules = [{ myconfig.constants = constants; }]; }).config;

  fixtureCheck =
    label: constants: bindName: want:
    let
      c = twin constants;
      got = commandOf c bindName;
    in
    {
      inherit label;
      result =
        if !(gnomeOn c) then
          "FAIL: fixture lost GNOME, check is vacuous"
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
    (fixtureCheck "control: GUI file manager is launched bare" { fileManager = force "nautilus"; } "Launch File Manager" "nautilus")
    (fixtureCheck "control: TUI editor is wrapped in the terminal" { editor = force "hx"; } "Launch editor" "kitty -e hx")
    (fixtureCheck "control: TUI role is launched bare once it leaves terminalApps"
      {
        fileManager = force "yazi";
        terminalApps = force [ ];
      } "Launch File Manager" "yazi")
    (fixtureCheck "control: wrapper uses constants.terminal.name"
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
    [
      (fixtureCheck "fixture: TUI file manager is wrapped in the terminal" { } "Launch File Manager" "kitty -e yazi")
      (fixtureCheck "fixture: GUI editor is launched bare" { } "Launch editor" "gedit")
    ]
    ++ lib.concatMap hostReport hostNames
  );
  control = render controls;
}
