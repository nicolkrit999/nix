let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hasNixos = flake.nixosConfigurations != { };
  hosts = {
    minimal = flake.nixosConfigurations.template-host-minimal;
    desktop = flake.nixosConfigurations.nixos-desktop;
    darwin = flake.darwinConfigurations.Krits-MacBook-Pro;
  };

  shells = [ "bash" "zsh" "fish" ];
  hmOf = host: host.config.home-manager.users.krit;

  mk =
    { host, shell ? null, fastfetch ? null, impure ? null, push ? false, nh ? null, gitWiring ? false }:
    let
      x = hosts.${host}.extendModules {
        modules = [
          ({ lib, ... }: lib.mkMerge [{
            myconfig.programs.atuin.enable = true;
            myconfig.programs.eza.enable = true;
            myconfig.programs.zoxide.enable = true;
            myconfig.services.tailscale.enable = true;
          }
            (lib.optionalAttrs (shell != null) {
              myconfig.constants.shell = lib.mkForce shell;
            })
            (lib.optionalAttrs (fastfetch != null) {
              myconfig.programs.fastfetch.enable = lib.mkForce fastfetch;
            })
            (lib.optionalAttrs (impure != null) {
              myconfig.constants.nixImpure = lib.mkForce impure;
            })
            (lib.optionalAttrs (nh != null) {
              myconfig.nh.enable = lib.mkForce nh;
            })
            (lib.optionalAttrs push {
              myconfig.cachix.push = lib.mkForce true;
              myconfig.cachix.authTokenPath = lib.mkForce "/run/test-token";
            })])
        ];
      };
      h = hmOf x;
      sh = x.config.myconfig.constants.shell;
      p = h.programs;
      nc = builtins.unsafeDiscardStringContext;
      texts = {
        bash = nc p.bash.initExtra;
        zsh = nc p.zsh.initContent;
        fish = nc p.fish.interactiveShellInit;
      };
      fnBodies = lib.mapAttrs (_: f: nc (if builtins.isString f then f else f.body)) p.fish.functions;
      enabledShells = lib.filter (s: p.${s}.enable) shells;
      integ = prog:
        lib.filter (s: p.${prog}.${"enable" + lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 99 s + "Integration"})
          (lib.filter (s: p.${prog} ? ${"enable" + lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 99 s + "Integration"}) shells);
      progs = [ "atuin" "eza" "fzf" "zoxide" "starship" "yazi" ];
      count = needle: hay: builtins.length (lib.splitString needle hay) - 1;
      has = needle: hay: lib.hasInfix needle hay;
      allText = lib.concatStringsSep "\n" (builtins.attrValues texts ++ builtins.attrValues fnBodies);
      active = texts.${sh};
      isDarwin = host == "darwin";
      splash = nc x.config.myconfig.programs.fastfetch.splashCommand;
      ffOn = x.config.myconfig.programs.fastfetch.enable;
      res = ok: msg: if ok then "ok" else "FAIL: ${msg}";
      checks =
        {
          "shell-is-${if shell == null then "host-default" else shell}" =
            res (shell == null || sh == shell) "constants.shell is ${sh}, forced ${toString shell}";
          "exactly-one-shell-enabled" =
            res (enabledShells == [ sh ]) "enabled shells ${builtins.toJSON enabledShells}, expected [${sh}]";
          "integrations-match-shell" =
            let
              bad = lib.filter (prog: p.${prog}.enable && integ prog != lib.filter (s: p.${prog} ? ${"enable" + lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 99 s + "Integration"}) [ sh ]) progs;
            in
            res (bad == [ ]) "integration flags disagree with shell ${sh} for ${builtins.toJSON bad}";
          "integrations-cover-programs" =
            res (lib.all (prog: p.${prog}.enable) [ "atuin" "eza" "fzf" "zoxide" "starship" ])
              "a program is not enabled so its integration flags were not compared";
          "inactive-shells-empty-of-startup" =
            let
              others = lib.filter (s: s != sh) shells;
              bad = lib.filter (s: has "uwsm" texts.${s} || has "tmux" texts.${s}) others;
            in
            res (bad == [ ]) "inactive shell(s) ${builtins.toJSON bad} carry startup code";
          "tailscale-helpers-in-active-shell" =
            res (if sh == "fish" then fnBodies ? tailscalenodeset && fnBodies ? tailscalenoderemove else has "tailscalenodeset()" active && has "tailscalenoderemove()" active)
              "tailscale exit-node helpers missing for ${sh}";
          "fastfetch-splash-matches-flag" =
            res (if ffOn then has "STARTUP SPLASH" active && has splash active else !(has "STARTUP SPLASH" active))
              "fastfetch enabled=${builtins.toJSON ffOn} but splash text presence disagrees";
        }
        // lib.optionalAttrs (sh == "bash") {
          "bash-sections-unnumbered" =
            let numbered = lib.filter (l: builtins.match "[[:space:]]*# [0-9]+[.].*" l != null) (lib.splitString "\n" active);
            in res (numbered == [ ]) "numbered section comments in bash init: ${builtins.toJSON numbered}";
        }
        // (if isDarwin then
          {
            "no-uwsm-or-hyprland-on-darwin" =
              res (!(has "uwsm" allText) && !(has "HYPRLAND_INSTANCE_SIGNATURE" allText))
                "Darwin shell init contains uwsm/Hyprland code";
            "tmux-autostart-execs-on-darwin" =
              res (has "exec tmux new-session" active) "Darwin ${sh} lacks always-on tmux autostart";
          }
          // lib.optionalAttrs (sh == "zsh") {
            "darwin-zsh-keychain-homebrew-on-system-path" =
              res (has "--apple-use-keychain" active && !(has "/opt/homebrew" active) && builtins.elem "/opt/homebrew/bin" (lib.splitString ":" x.config.environment.systemPath))
                "Darwin zsh lacks --apple-use-keychain, still prepends /opt/homebrew, or /opt/homebrew/bin is missing from environment.systemPath";
          }
          // lib.optionalAttrs (sh != "zsh") {
            "no-homebrew-or-keychain-outside-zsh" =
              res (!(has "apple-use-keychain" allText)) "keychain flag leaked into ${sh}";
          }
          // lib.optionalAttrs (sh == "bash") {
            "darwin-bash-no-display-gate" =
              res (!(has "$DISPLAY" active)) "Darwin bash init still gates on $DISPLAY";
          }
        else
          {
            "uwsm-start-exactly-once" =
              res (count "uwsm start default" allText == 1)
                "'uwsm start default' appears ${toString (count "uwsm start default" allText)} times across shells";
            "hyprland-signature-in-active-shell" =
              res (has "HYPRLAND_INSTANCE_SIGNATURE" active) "${sh} init lacks HYPRLAND_INSTANCE_SIGNATURE fix";
            "no-homebrew-on-nixos" =
              res (!(has "/opt/homebrew" allText) && !(has "apple-use-keychain" allText))
                "NixOS shell init contains Darwin-only text";
          }
          // lib.optionalAttrs (sh == "bash") {
            "nixos-bash-tmux-display-gated" =
              res (has "[ -n \"$DISPLAY\" ]; then\n  tmux new-session -A -s main" active && !(has "exec tmux" active))
                "NixOS bash tmux autostart is not the DISPLAY-gated, non-exec form";
          });

      aliases = lib.mapAttrs (_: nc) h.home.shellAliases;
      F = "~/${x.config.myconfig.constants.flakeDir}";
      hostName = x.config.myconfig.constants.hostname;
      nhOn = x.config.myconfig.nh.enable;
      pre = git: "cd ${F} && ${lib.optionalString git "git add -A && "}";
      failIf = probs: if probs == [ ] then "ok" else "FAIL: ${lib.concatStringsSep "; " probs}";
      aliasIs = name: want:
        lib.optional ((aliases.${name} or null) != want) "${name} = ${builtins.toJSON (aliases.${name} or null)}, expected ${builtins.toJSON want}";
      aliasWhere = names: pred: why:
        map (n: "${n} ${why}: ${builtins.toJSON (aliases.${n} or null)}") (lib.filter (n: !(aliases ? ${n}) || !(pred aliases.${n})) names);
      nhMsg = "myconfig.nh.enable is false";
      impureVal = x.config.myconfig.constants.nixImpure;
      nhAssertFires = cfg: lib.any (a: !a.assertion && has nhMsg a.message) cfg.config.assertions;
      pureTwin = x.extendModules { modules = [ ({ lib, ... }: { myconfig.constants.nixImpure = lib.mkOverride 10 false; }) ]; };
      nhAssertionChecks = {
        "nh-assertion-${if nhOn then "nhon" else "nhoff"}-${if impureVal then "impure" else "pure"}" =
          res (nhAssertFires x == (!nhOn && !impureVal))
            "nh-off assertion fires=${builtins.toJSON (nhAssertFires x)} with nh.enable=${builtins.toJSON nhOn}, nixImpure=${builtins.toJSON impureVal}";
      }
      // lib.optionalAttrs (!nhOn) {
        "nh-off-pure-twin-asserts" =
          res (nhAssertFires pureTwin) "nh off with nixImpure=false did not fire the nh assertion";
      };
      nixosRebuildAliases = [ "sw" "swboot" "swtest" "swdry" "swfall" "gsw" "gswfall" "gswoff" "swsrc" "swoff" "tswsrc" "upd" ];
      darwinRebuildAliases = [ "sw" "swfall" "gsw" "gswfall" "swdry" "gswoff" "upd" ];
      darwinRebuild = "sudo darwin-rebuild switch --flake .#${hostName} --impure";
      nixosImpureChecks = {
        "impure-rebuild-aliases-no-nh" =
          failIf (aliasWhere nixosRebuildAliases (v: has "nixos-rebuild " v && has "--impure" v && !(has "nh os" v)) "is not an impure nixos-rebuild command");
        "impure-dry-and-offline-texts" = failIf (
          aliasIs "swdry" "${pre true}nixos-rebuild dry-build --flake . --impure"
          ++ aliasIs "swoff" "${pre false}sudo nixos-rebuild switch --flake . --impure --offline"
          ++ aliasIs "gswoff" "${pre true}sudo nixos-rebuild switch --flake . --impure --offline"
        );
        "swpure-pure-nh-${if nhOn then "on" else "off"}" = failIf (
          aliasIs "swpure" "${pre true}${if nhOn then "nh os switch ${F}" else "sudo nixos-rebuild switch --flake ."}"
        );
      };
      nixosPureChecks = {
        "pure-nh-texts-unchanged" = failIf (
          aliasIs "swdry" "${pre true}nh os switch ${F} --dry"
          ++ aliasIs "swoff" "${pre false}nh os switch ${F} -- --offline"
          ++ aliasIs "gswoff" "${pre true}nh os switch ${F} -- --offline"
          ++ aliasIs "swpure" "${pre true}nh os switch ${F}"
          ++ aliasWhere [ "swboot" ] (lib.hasPrefix "${pre true}nh os boot ${F}") "does not start with nh os boot"
          ++ aliasWhere [ "upd" ] (lib.hasPrefix "${pre true}nh os switch --update ${F}") "does not start with nh os switch --update"
        );
      };
      darwinImpureChecks = {
        "darwin-impure-rebuild-aliases-no-nh" =
          failIf (aliasWhere darwinRebuildAliases (v: has "darwin-rebuild " v && has "--impure" v && !(has "nh darwin" v)) "is not an impure darwin-rebuild command");
        "darwin-impure-texts" = failIf (
          aliasWhere [ "sw" ] (lib.hasPrefix "${pre false}${darwinRebuild}") "does not start with ${darwinRebuild}"
          ++ aliasIs "swdry" "${pre true}darwin-rebuild build --flake .#${hostName} --impure --dry-run"
          ++ aliasIs "gswoff" "${pre true}${darwinRebuild} --offline"
        );
      };
      darwinPureChecks = {
        "darwin-pure-nh-texts-unchanged" = failIf (
          aliasWhere [ "sw" ] (lib.hasPrefix "${pre false}nh darwin switch ${F}") "does not start with nh darwin switch"
          ++ aliasIs "swdry" "${pre true}nh darwin switch ${F} --dry"
          ++ aliasIs "gswoff" "${pre true}nh darwin switch ${F} -- --offline"
        );
      };
      pathInfo = path: "nix path-info -r ${path} ";
      pushPathChecks = {
        "swboot-pushes-system-profile" = failIf (
          aliasWhere [ "swboot" ] (v: has (pathInfo "/nix/var/nix/profiles/system") v && !(has "/run/current-system" v)) "does not push /nix/var/nix/profiles/system"
          ++ aliasWhere [ "sw" ] (v: has (pathInfo "/run/current-system") v && !(has "/nix/var/nix/profiles/system" v)) "does not push /run/current-system"
        );
      };

      gitTwin = name: email: fd:
        let
          y = x.extendModules {
            modules = [
              ({ lib, ... }: {
                myconfig.constants = {
                  gitUserName = lib.mkForce name;
                  gitUserEmail = lib.mkForce email;
                } // lib.optionalAttrs (fd != null) { flakeDir = lib.mkForce fd; };
              })
            ];
          };
          hy = hmOf y;
        in
        {
          text = nc hy.xdg.configFile."git/config".text;
          hook = nc hy.home.activation.setupNixRepoHooks.data;
          flakeDir = y.config.myconfig.constants.flakeDir;
        };
      userKeys = text:
        let
          sections = lib.filter (lib.hasPrefix "user]") (lib.splitString "\n[" ("\n" + text));
          pairs = lib.concatMap (sec: lib.concatMap (l: let mm = builtins.match "[[:space:]]+([A-Za-z]+) = (.*)" l; in lib.optional (mm != null) (lib.nameValuePair (builtins.elemAt mm 0) (builtins.elemAt mm 1))) (lib.splitString "\n" sec)) sections;
        in
        builtins.listToAttrs pairs;
      q = v: "\"${v}\"";
      testName = "Test User";
      testEmail = "test@example.invalid";
      hookProblems = t:
        let home = "$HOME/${t.flakeDir}"; in
        lib.optional (!(has "[ -d \"${home}/.git\" ]" t.hook)) "hook does not test ${home}/.git"
        ++ lib.optional (!(has "-C \"${home}\" config core.hooksPath .githooks" t.hook)) "hook does not set core.hooksPath .githooks in ${home}";
      gitChecks = {
        "git-identity-empty-omitted" =
          let k = userKeys (gitTwin "" "" null).text;
          in res (!(k ? name) && !(k ? email)) "empty constants still write [user] ${builtins.toJSON k}";
        "git-identity-set-written" =
          let k = userKeys (gitTwin testName testEmail null).text;
          in res ((k.name or null) == q testName && (k.email or null) == q testEmail) "set constants not written: [user] ${builtins.toJSON k}";
        "git-identity-per-key" =
          let k = userKeys (gitTwin testName "" null).text;
          in res ((k.name or null) == q testName && !(k ? email)) "name-only constants: [user] ${builtins.toJSON k}";
        "git-hooks-default-flakedir" =
          failIf (hookProblems (gitTwin "" "" null));
        "git-hooks-follow-flakedir" =
          let t = gitTwin "" "" "src/flake-under-test";
          in failIf (hookProblems t ++ lib.optional (t.flakeDir != "src/flake-under-test") "flakeDir override not applied" ++ lib.optional (has "$HOME/nix" t.hook) "hook still names $HOME/nix");
      };
      pkgNames = map (q: nc (q.name or q.pname or "")) h.home.packages;
      aliasChecks =
        {
          "tpm-reenroll-${if isDarwin then "absent" else "present"}" = res ((builtins.elem "tpm-reenroll" pkgNames) == !isDarwin && !(aliases ? tpm-reenroll))
            "tpm-reenroll package presence wrong (packages: ${builtins.toJSON pkgNames})";
          "deadnix-unpinned" =
            res (has "github:astro/deadnix --" aliases.deadnixfixall && has "github:astro/deadnix --" aliases.deadnixscanall)
              "deadnix aliases should follow upstream HEAD (no tag pin)";
          "nfc-impure-${if isDarwin then "yes" else "no"}" =
            res (has "--impure" aliases.nfc == isDarwin) "nfc --impure presence wrong: ${aliases.nfc}";
        }
        // lib.optionalAttrs (impure != null && !isDarwin) {
          "sw-impure-${if impure then "true" else "false"}" =
            res (if impure then has "--impure" aliases.sw && !(has "nh os switch" aliases.sw) else has "nh os switch" aliases.sw && !(has "--impure" aliases.sw))
              "sw alias wrong for nixImpure=${builtins.toJSON impure}: ${aliases.sw}";
        }
        // lib.optionalAttrs push {
          "push-aliases-use-sh-c" =
            res (lib.any (v: has "sh -c" v) (builtins.attrValues aliases)) "no alias contains sh -c with cachix push forced";
        }
        // lib.optionalAttrs (push && !isDarwin) pushPathChecks
        // lib.optionalAttrs (impure == true && !isDarwin) nixosImpureChecks
        // lib.optionalAttrs (impure == false && !isDarwin) nixosPureChecks
        // lib.optionalAttrs (impure == true && isDarwin) darwinImpureChecks
        // lib.optionalAttrs (impure == false && isDarwin) darwinPureChecks
        // lib.optionalAttrs (impure != null || nh != null) nhAssertionChecks
        // lib.optionalAttrs gitWiring gitChecks;
    in
    {
      checks = checks // aliasChecks;
      files = {
        bash = texts.bash;
        zsh = texts.zsh;
        fish = texts.fish;
      }
      // lib.mapAttrs' (n: v: lib.nameValuePair "fishfn-${n}" v) fnBodies
      // lib.optionalAttrs (isDarwin && sh == "fish") { sys-zsh = nc x.config.programs.zsh.interactiveShellInit; };
      shAliases = lib.filterAttrs (_: v: has "sh -c" v) aliases;
    };

  variants =
    lib.listToAttrs
      (lib.concatMap
        (s: map
          (ff: {
            name = "nixos-${s}-ff${if ff then "on" else "off"}";
            value = { host = "minimal"; shell = s; fastfetch = ff; };
          }) [ true false ])
        shells)
    // {
      "nixos-bash-impure" = { host = "minimal"; shell = "bash"; impure = true; push = true; };
      "nixos-bash-impure-nhoff" = { host = "minimal"; shell = "bash"; impure = true; nh = false; };
      "nixos-bash-pure" = { host = "minimal"; shell = "bash"; impure = false; };
      "nixos-git-wiring" = { host = "minimal"; shell = "bash"; gitWiring = true; };
      "nixos-desktop-real" = { host = "desktop"; };
      "darwin-real" = { host = "darwin"; };
      "darwin-zsh-ffon" = { host = "darwin"; shell = "zsh"; fastfetch = true; };
      "darwin-bash-ffon" = { host = "darwin"; shell = "bash"; fastfetch = true; impure = false; };
      "darwin-impure" = { host = "darwin"; impure = true; };
      "darwin-impure-nhoff" = { host = "darwin"; impure = true; nh = false; };
    };

  mkHome = impure:
    let
      x = flake.homeConfigurations."krit@Nicol-NAS".extendModules {
        modules = [{ myconfig.constants.nixImpure = lib.mkForce impure; }];
      };
      aliases = lib.mapAttrs (_: builtins.unsafeDiscardStringContext) x.config.home.shellAliases;
      res = ok: msg: if ok then "ok" else "FAIL: ${msg}";
      impureAliases = [ "sw" "gsw" "swdry" "upd" "nfc" ];
      bad = lib.filter (n: lib.hasInfix "--impure" aliases.${n} != impure) impureAliases;
    in
    {
      checks = {
        "home-impure-${if impure then "true" else "false"}" =
          res (bad == [ ]) "home aliases ${builtins.toJSON bad} disagree with nixImpure=${builtins.toJSON impure}: ${builtins.toJSON (lib.genAttrs bad (n: aliases.${n}))}";
        "home-hm-gens-untouched" =
          res (aliases.hm-gens == "home-manager generations") "hm-gens alias changed: ${aliases.hm-gens}";
      };
      files = { };
      shAliases = { };
    };

  homeVariants = lib.optionalAttrs hasNixos {
    "home-impure" = mkHome true;
    "home-pure" = mkHome false;
  };

  nixosOnly = n: lib.hasPrefix "nixos-" n;
  available = lib.filterAttrs (n: _: hasNixos || !nixosOnly n) variants;
in
{
  inherit hasNixos;
  names = builtins.attrNames (available // homeVariants);
  variant = lib.mapAttrs (_: mk) available // homeVariants;
}
