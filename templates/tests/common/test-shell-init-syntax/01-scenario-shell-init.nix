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
    { host, shell ? null, fastfetch ? null, impure ? null, push ? false }:
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
        // (if isDarwin then
          {
            "no-uwsm-or-hyprland-on-darwin" =
              res (!(has "uwsm" allText) && !(has "HYPRLAND_INSTANCE_SIGNATURE" allText))
                "Darwin shell init contains uwsm/Hyprland code";
            "tmux-autostart-execs-on-darwin" =
              res (has "exec tmux new-session" active) "Darwin ${sh} lacks always-on tmux autostart";
          }
          // lib.optionalAttrs (sh == "zsh") {
            "darwin-zsh-homebrew-and-keychain" =
              res (has "/opt/homebrew/bin" active && has "--apple-use-keychain" active)
                "Darwin zsh lacks /opt/homebrew/bin or --apple-use-keychain";
          }
          // lib.optionalAttrs (sh != "zsh") {
            "no-homebrew-or-keychain-outside-zsh" =
              res (!(has "apple-use-keychain" allText)) "keychain flag leaked into ${sh}";
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
          });

      aliases = lib.mapAttrs (_: nc) h.home.shellAliases;
      pkgNames = map (q: nc (q.name or q.pname or "")) h.home.packages;
      aliasChecks =
        {
          "tpm-reenroll-${if isDarwin then "absent" else "present"}" = res ((builtins.elem "tpm-reenroll" pkgNames) == !isDarwin && !(aliases ? tpm-reenroll))
            "tpm-reenroll package presence wrong (packages: ${builtins.toJSON pkgNames})";
          "deadnix-pinned" =
            res (has "deadnix/v1.3.2" aliases.deadnixfixall && has "deadnix/v1.3.2" aliases.deadnixscanall)
              "deadnix aliases not pinned to v1.3.2";
          "nfc-impure-${if isDarwin then "yes" else "no"}" =
            res (has "--impure" aliases.nfc == isDarwin) "nfc --impure presence wrong: ${aliases.nfc}";
        }
        // lib.optionalAttrs (impure != null) {
          "sw-impure-${toString impure}" =
            res (if impure then has "--impure" aliases.sw && !(has "nh os switch" aliases.sw) else has "nh os switch" aliases.sw && !(has "--impure" aliases.sw))
              "sw alias wrong for nixImpure=${builtins.toJSON impure}: ${aliases.sw}";
        }
        // lib.optionalAttrs push {
          "push-aliases-use-sh-c" =
            res (lib.any (v: has "sh -c" v) (builtins.attrValues aliases)) "no alias contains sh -c with cachix push forced";
        };
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
      "nixos-bash-pure" = { host = "minimal"; shell = "bash"; impure = false; };
      "nixos-desktop-real" = { host = "desktop"; };
      "darwin-real" = { host = "darwin"; };
      "darwin-zsh-ffon" = { host = "darwin"; shell = "zsh"; fastfetch = true; };
    };

  nixosOnly = n: lib.hasPrefix "nixos-" n;
  available = lib.filterAttrs (n: _: hasNixos || !nixosOnly n) variants;
in
{
  inherit hasNixos;
  names = builtins.attrNames available;
  variant = lib.mapAttrs (_: mk) available;
}
