let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  fx = import ../../lib/fixture-host.nix flake;
  inherit (flake.inputs.nixpkgs) lib;

  flag = "--password-store=gnome-libsecret";
  has = lib.hasInfix;
  carries = p: lib.any (n: let v = p.drvAttrs.${n}; in builtins.isString v && has flag v) (builtins.attrNames p.drvAttrs);
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";

  infixes = [ "brave" "chromium" "google-chrome" "vscode" ];
  pkgsModule = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = [ pkgs.brave pkgs.chromium pkgs.google-chrome pkgs.vscode ];
  };

  pkgHost = fx.mkNixos [ pkgsModule ];
  installed = pkgHost.config.environment.systemPackages;
  byInfix = s: lib.filter (p: has s (p.name or "")) installed;
  unflagged = pkgHost.pkgs.brave.override { commandLineArgs = ""; };
  unflaggedChromium = pkgHost.pkgs.chromium.override { commandLineArgs = ""; };

  chromiumOn = { myconfig.krit.programs.chromium.enable = true; };
  heliumOn = { myconfig.krit.programs.helium.enable = true; };
  chromiumHm = fx.hmOf (fx.mkNixos [ chromiumOn ]);
  chromiumUnpinned = fx.hmOf (fx.mkNixos [ chromiumOn { home-manager.users.krit.programs.chromium = { commandLineArgs = lib.mkForce [ ]; package = lib.mkForce unflaggedChromium; }; } ]);
  heliumHm = fx.hmOf (fx.mkNixos [ heliumOn ]);
  heliumUnpinned = fx.hmOf (fx.mkNixos [ heliumOn { home-manager.users.krit.programs.helium.extraFlags = lib.mkForce [ ]; } ]);

  fhsHost = fx.mkNixos [ { nixpkgs.config.allowUnfree = true; myconfig.programs.claude-desktop.enable = true; myconfig.programs.google-antigravity.enable = true; } ];
  fhsInstalled = fhsHost.config.environment.systemPackages;
  fhsByInfix = s: lib.filter (p: has s (p.name or "")) fhsInstalled;
  fhsApps = [ "claude-desktop" "antigravity" ];

  chromiumPinned = hm: hm.programs.chromium.enable && (lib.elem flag hm.programs.chromium.commandLineArgs || carries hm.programs.chromium.package);
  heliumPinned = hm: hm.programs.helium.enable && lib.elem flag hm.programs.helium.extraFlags;
in
{
  report = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (k: v: "${k}\t${v}") ({
      "fixture: each browser family is installed" =
        chk (lib.all (s: byInfix s != [ ]) infixes) "missing families: ${toString (lib.filter (s: byInfix s == [ ]) infixes)}";
      "fixture: every installed browser carries gnome-libsecret" =
        chk (lib.all (s: lib.all carries (byInfix s)) infixes) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) installed))}";
      "control: a browser without the override does not carry the flag" =
        chk (!(carries unflagged)) "carries matched an unflagged brave";
      "fixture: FHS-wrapped Electron apps are installed" =
        chk (lib.all (s: fhsByInfix s != [ ]) fhsApps) "missing apps: ${toString (lib.filter (s: fhsByInfix s == [ ]) fhsApps)}";
      "fixture: FHS-wrapped Electron apps carry gnome-libsecret" =
        chk (lib.all (s: lib.all carries (fhsByInfix s)) fhsApps) "without the flag: ${toString (map (p: p.name) (lib.filter (p: !(carries p)) (lib.concatMap fhsByInfix fhsApps)))}";
      "control: the unwrapped claude-desktop-fhs does not carry the flag" =
        chk (!(carries fhsHost.pkgs.claude-desktop-fhs)) "carries matched an unwrapped claude-desktop-fhs";
      "control: the unwrapped antigravity does not carry the flag" =
        chk (!(carries fhsHost.pkgs.google-antigravity-no-fhs)) "carries matched an unwrapped antigravity";
      "fixture: HM chromium is pinned" = chk (chromiumPinned chromiumHm && lib.elem flag chromiumHm.programs.chromium.commandLineArgs) "HM chromium enabled but its module does not pin the flag";
      "control: HM chromium without args is detected as unpinned" = chk (!(chromiumPinned chromiumUnpinned)) "unpinned chromium passed the predicate";
      "fixture: HM helium is pinned" = chk (heliumPinned heliumHm) "HM helium enabled but not pinned";
      "control: HM helium without extraFlags is detected as unpinned" = chk (!(heliumPinned heliumUnpinned)) "unpinned helium passed the predicate";
    })) + "\n";
}
