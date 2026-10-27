let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  fx = import ../../lib/fixture-host.nix flake;
  lib = flake.inputs.nixpkgs.lib;

  mk = lib.mkForce;
  over = lib.mkOverride 10;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  lingerDir = "/var/lib/systemd/linger";
  persisted = cfg: map (d: d.directory) (cfg.environment.persistence."/persist".directories or [ ]);
  coffeeOnText = builtins.readFile "${flake.outPath}/modules/nixos/services/power/coffee/coffee-on.sh";
  staleHandling = text: lib.hasInfix "-f $LINGER_MARKER && $linger != yes" text;
  lingerProblems = cfg: onText:
    let
      impOn = cfg.myconfig.services.impermanence.enable;
      coffeeOn = cfg.myconfig.services.coffee.enable;
    in
    if !impOn then [ "impermanence is off, the check is vacuous" ]
    else if !coffeeOn then [ "coffee is off, the check is vacuous" ]
    else lib.optional (!(builtins.elem lingerDir (persisted cfg)) && !staleHandling onText)
      "${lingerDir} is not persisted and coffee-on.sh has no stale linger marker handling";

  base = { myconfig.services.coffee.enable = mk true; myconfig.services.impermanence.enable = mk true; };
  fixture = (fx.mkNixos [ base ]).config;
  noLinger = (fx.mkNixos [ base { environment.persistence."/persist".directories = over [ ]; } ]).config;
  noImpermanence = (fx.mkNixos [ base { myconfig.services.impermanence.enable = over false; } ]).config;
  noCoffee = (fx.mkNixos [ base { myconfig.services.coffee.enable = over false; } ]).config;

  checks = {
    "coffee: linger dir persisted, or coffee-on.sh handles a stale linger marker" = failIf (lingerProblems fixture coffeeOnText);
    "control(coffee): unpersisted linger without stale handling is detected" = detects "no persistence" (lingerProblems noLinger "nothing");
    "control(coffee): stale marker handling in coffee-on.sh is what makes an unpersisted linger acceptable" = failIf (lingerProblems noLinger coffeeOnText);
    "control(coffee): impermanence off is flagged as vacuous" = detects "impermanence off" (lingerProblems noImpermanence coffeeOnText);
    "control(coffee): coffee off is flagged as vacuous" = detects "coffee off" (lingerProblems noCoffee coffeeOnText);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
