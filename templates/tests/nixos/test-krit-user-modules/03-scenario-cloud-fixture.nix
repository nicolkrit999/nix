let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  fx = import ../../lib/fixture-host.nix flake;
  inherit (flake.inputs.nixpkgs) lib;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  show = builtins.toJSON;

  cloudOpts = { google-drive = "googleDrive"; onedrive-personal = "onedrivePersonal"; pcloud = "pcloud"; proton-drive = "protonDrive"; };
  cloudNames = lib.attrNames cloudOpts;
  one = n: fx.mkNixos [{ myconfig.krit.services.cloud.${cloudOpts.${n}}.enable = true; }];
  all = fx.mkNixos [{ myconfig.krit.services.cloud = lib.mapAttrs' (_: o: lib.nameValuePair o { enable = true; }) cloudOpts; }];
  none = fx.mkNixos [ ];

  cloudDefs = h: lib.filter (d: lib.hasInfix "/services/cloud/" (toString d.file))
    h.options.myconfig.services.rcloneMount.enable.definitionsWithLocations;
  fromModule = n: h: lib.filter (d: lib.hasSuffix "/services/cloud/${n}.nix" (toString d.file)) (cloudDefs h);
  rclone = h: h.config.myconfig.services.rcloneMount.enable;

  checks = {
    check-each-cloud-module-enables-rclone-mount = check
      (lib.all (n: let h = one n; in lib.length (fromModule n h) == 1 && (lib.head (fromModule n h)).value == true && rclone h) cloudNames)
      "a cloud module alone does not define rcloneMount.enable = true from its own file: ${show (map (n: [ n (map (d: toString d.file) (fromModule n (one n))) ]) cloudNames)}";
    check-all-cloud-modules-one-definition-each = check
      (lib.length (cloudDefs all) == lib.length cloudNames && lib.all (d: d.value == true) (cloudDefs all))
      "definitions from services/cloud with every module on: ${show (map (d: toString d.file) (cloudDefs all))}";
    check-control-no-cloud-module-no-definition = check
      (cloudDefs none == [ ] && !(rclone none))
      "cloud definitions or rcloneMount without any cloud module: ${show (map (d: toString d.file) (cloudDefs none))}";
  };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
