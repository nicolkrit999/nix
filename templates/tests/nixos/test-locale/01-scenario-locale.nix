# services.locale contract on a fresh fixture host (only modules/nixos/services/locale.nix):
#  - enabled without values every LC_* category and the display-manager LC_TIME fall back to en_US.UTF-8;
#    disabled writes none of them
#  - LC_TIME cannot be split: one locale carries the 12/24-hour clock, date order, names and week start, so
#    `time` is a single string and the display manager gets exactly that value (mkDefault, overridable)
#  - spelling trap (nixpkgs#256688): NixOS builds i18n.supportedLocales as "<value>/UTF-8" but glibc lists
#    en_IN as "en_IN/UTF-8", so `time = "en_IN"` builds and `time = "en_IN.UTF-8"` fails the glibc-locales
#    build; the bare-name checks need the real build (`locales.*`), the eval checks only pin the mapping
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;
  shared = src + "/templates/tests/nixos/test-locale/shared";

  host = (denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (shared + "/host-locale.nix")
      (shared + "/nixos-extra-x86_64")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/services/locale.nix")
    ];
    exclude = [ ];
  }).locale-host;

  force = lib.mkOverride 10;
  twin = mods: (host.extendModules { modules = lib.toList mods; }).config;
  loc = o: { myconfig.services.locale = o; };

  cats = [ "address" "identification" "measurement" "monetary" "name" "numeric" "paper" "telephone" "time" ];
  eight = lib.filter (c: c != "time") cats;
  keyOf = c: "LC_${lib.toUpper c}";
  sortedKeys = lib.sort builtins.lessThan (map keyOf cats);

  swissVals = lib.genAttrs eight (_: "it_CH.UTF-8") // { time = "en_IN"; };
  distinctVals = {
    address = "de_CH.UTF-8";
    identification = "fr_CH.UTF-8";
    measurement = "it_CH.UTF-8";
    monetary = "de_DE.UTF-8";
    name = "fr_FR.UTF-8";
    numeric = "es_ES.UTF-8";
    paper = "pt_PT.UTF-8";
    telephone = "nl_NL.UTF-8";
    time = "en_GB.UTF-8";
  };

  us = host.config;
  off = twin (loc { enable = force false; });
  swiss = twin (loc swissVals);
  distinct = twin (loc distinctVals);
  partial = twin (loc { time = "en_IN"; });
  bad = twin (loc (swissVals // { time = "en_IN.UTF-8"; }));
  dmOverride = twin [ (loc swissVals) { systemd.services.display-manager.environment.LC_TIME = "overridden"; } ];

  lcKeys = c: lib.sort builtins.lessThan (lib.filter (k: lib.hasPrefix "LC_" k) (builtins.attrNames c.i18n.extraLocaleSettings));
  valueOf = c: cat: c.i18n.extraLocaleSettings.${keyOf cat} or null;
  allAre = c: want: lcKeys c == sortedKeys && lib.all (cat: valueOf c cat == want cat) cats;
  dmTime = c: c.systemd.services.display-manager.environment.LC_TIME or null;
  has = x: xs: builtins.elem x xs;
  show = c: builtins.toJSON c.i18n.extraLocaleSettings;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";

  checks = {
    "defaults: enabled with no values writes all nine LC_* as en_US.UTF-8" =
      chk (allAre us (_: "en_US.UTF-8")) (show us);
    "defaults: display-manager LC_TIME is en_US.UTF-8" =
      chk (dmTime us == "en_US.UTF-8") "LC_TIME=${toString (dmTime us)}";
    "disabled: no LC_* in extraLocaleSettings and no display-manager LC_TIME" =
      chk (lcKeys off == [ ] && dmTime off == null) "${show off} / ${toString (dmTime off)}";
    "control(disabled): the enabled host writes both, so the disabled result is not an unloaded module" =
      chk (lcKeys us != [ ] && dmTime us != null && lcKeys us != lcKeys off) (show us);
    "host values: eight categories it_CH.UTF-8, time en_IN" =
      chk (allAre swiss (cat: swissVals.${cat})) (show swiss);
    "host values: display-manager LC_TIME is en_IN" =
      chk (dmTime swiss == "en_IN") "LC_TIME=${toString (dmTime swiss)}";
    "host values: supportedLocales has en_IN/UTF-8 and it_CH.UTF-8/UTF-8, not en_IN.UTF-8/UTF-8" =
      chk
        (has "en_IN/UTF-8" swiss.i18n.supportedLocales && has "it_CH.UTF-8/UTF-8" swiss.i18n.supportedLocales
          && !has "en_IN.UTF-8/UTF-8" swiss.i18n.supportedLocales)
        (builtins.toJSON swiss.i18n.supportedLocales);
    "control(spelling): time = en_IN.UTF-8 maps to en_IN.UTF-8/UTF-8 and drops en_IN/UTF-8" =
      chk
        (has "en_IN.UTF-8/UTF-8" bad.i18n.supportedLocales && !has "en_IN/UTF-8" bad.i18n.supportedLocales)
        (builtins.toJSON bad.i18n.supportedLocales);
    "wiring: nine distinct values each reach their own LC_* key" =
      chk
        (builtins.length (lib.unique (lib.attrValues distinctVals)) == 9 && allAre distinct (cat: distinctVals.${cat}))
        (show distinct);
    "partial: only time set, the eight others stay en_US.UTF-8" =
      chk
        (allAre partial (cat: if cat == "time" then "en_IN" else "en_US.UTF-8") && dmTime partial == "en_IN")
        "${show partial} / ${toString (dmTime partial)}";
    "display-manager LC_TIME is a mkDefault: a plain definition wins without a conflict" =
      chk (dmTime dmOverride == "overridden" && valueOf dmOverride "time" == "en_IN")
        "dm=${toString (dmTime dmOverride)} time=${toString (valueOf dmOverride "time")}";
    "control(checker): a wrong expectation is rejected" =
      chk (!allAre swiss (_: "en_US.UTF-8") && !allAre off (_: "en_US.UTF-8") && !allAre us (cat: swissVals.${cat}))
        "allAre accepted a wrong expectation";
    "tools: glibcLocales and the glibc `locale` binary come from the same pkgs" =
      chk (us.i18n.glibcLocales.version == host.pkgs.glibc.version)
        "${us.i18n.glibcLocales.version} vs ${host.pkgs.glibc.version}";
  };

  pkgs = host.pkgs;
in
{
  checks = lib.mapAttrs (_: guard) checks;

  tools = pkgs.runCommand "locale-tools" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.glibc.bin}/bin/locale $out/bin/locale
    ln -s ${pkgs.coreutils}/bin/date $out/bin/date
  '';

  locales = {
    us = us.i18n.glibcLocales;
    host = swiss.i18n.glibcLocales;
    bad = bad.i18n.glibcLocales;
  };
}
