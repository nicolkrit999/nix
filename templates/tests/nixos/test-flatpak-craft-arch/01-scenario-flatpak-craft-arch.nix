let
  flakeRoot =
    let
      r = builtins.getEnv "FLAKE_ROOT";
    in
    if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  pkgsFor = system: import flake.inputs.nixpkgs { inherit system; };
  fakeDelib = {
    module = args: args;
    singleEnableOption = default: default;
  };

  load =
    path: system:
    import path {
      delib = fakeDelib;
      inherit (flake) inputs;
      pkgs = pkgsFor system;
    };
  assertionsOf =
    path: system:
    ((load path system).nixos.ifEnabled { myconfig.constants.timeZone = "UTC"; }).assertions;

  files = {
    desktop = "${flakeRoot}/hosts/nixos-desktop/flatpak.nix";
    laptop = "${flakeRoot}/hosts/nixos-laptop/flatpak.nix";
  };

  expect =
    path: system: wantPass:
    let
      m = load path system;
      prefix = "${m.name}:";
      mine = lib.filter (a: lib.hasPrefix prefix a.message) (assertionsOf path system);
    in
    if mine == [ ] then
      "FAIL: no assertion with message prefix '${prefix}' on ${system}"
    else if lib.all (a: a.assertion == wantPass) mine then
      "ok"
    else
      "FAIL: ${m.name} on ${system}: assertion held=${lib.boolToString (!wantPass)}, expected ${lib.boolToString wantPass}";

  mutant =
    path:
    let
      text = builtins.readFile path;
      broken = builtins.replaceStrings [ "hostPlatform.isx86_64" ] [ "hostPlatform.isLinux" ] text;
    in
    assert broken != text;
    builtins.toFile "flatpak-mutant.nix" broken;

  rows = lib.concatMapStrings (l: l + "\n") (
    lib.concatMap
      (
        which:
        let
          path = files.${which};
        in
        [
          "${which}: fails on aarch64-linux\t${expect path "aarch64-linux" false}"
          "${which}: passes on x86_64-linux\t${expect path "x86_64-linux" true}"
        ]
      )
      (builtins.attrNames files)
  );

  control = lib.concatMapStrings (l: l + "\n") (
    map
      (
        which:
        let
          r = expect (mutant files.${which}) "aarch64-linux" false;
        in
        "control: ${which} check rejects a mutant without isx86_64\t${
          if lib.hasPrefix "FAIL" r then "ok" else "FAIL: mutant passed the aarch64 check"
        }"
      )
      (builtins.attrNames files)
  );
in
{
  inherit rows control;
}
