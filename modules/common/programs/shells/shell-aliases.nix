{ delib, moduleSystem, lib, pkgs, ... }:
delib.module {
  name = "programs.shell-aliases";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    let
      pythonEnv = pkgs.python3.withPackages (ps: [ ps.requests ]);
      npu = pkgs.writeShellScriptBin "npu" ''
        export NIX_PREFETCH_URL="${pkgs.nix}/bin/nix-prefetch-url"
        exec ${pythonEnv}/bin/python3 ${./npu.py} "$@"
      '';

      flakeDir = "~/nix";
      safeEditor = myconfig.constants.editor;
      isImpure = myconfig.constants.nixImpure or false;
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";
      isHome = moduleSystem == "home";

      nixosSwitchCmd =
        if isImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

      nixosUpdateCmd =
        if isImpure then
          "nix flake update && sudo nixos-rebuild switch --flake . --impure"
        else
          "nh os switch --update ${flakeDir}";

      nixosBootCmd =
        if isImpure then
          "sudo nixos-rebuild boot --flake . --impure"
        else
          "nh os boot ${flakeDir}";

      nixosTestCmd =
        if isImpure then
          "sudo nixos-rebuild test --flake . --impure"
        else
          "nh os test ${flakeDir}";

      atticEnabled =
        (myconfig.krit.attic.enable or false) && (myconfig.krit.attic.push or false);
      cachixEnabled =
        (myconfig.cachix.enable or false) && (myconfig.cachix.push or false);

      atticServer = myconfig.krit.attic.serverUrl;
      atticCache = myconfig.krit.attic.cacheName;
      atticToken = myconfig.krit.attic.authTokenPath;
      atticPush =
        "attic login nas-push ${atticServer} \"$(cat ${atticToken})\""
        + " && nix path-info -r /run/current-system | attic push -j 8 nas-push:${atticCache} --stdin";

      cName =
        if myconfig.cachix.name == "use-constant" then
          myconfig.constants.cachix.name
        else
          myconfig.cachix.name;
      cachixTokenPath = myconfig.cachix.authTokenPath or "";
      # `env VAR=val cachix` (not the `VAR=val cmd` prefix) - fish has no inline
      # env-assignment syntax, and `env` wraps the last pipe stage so the token
      # reaches cachix.
      cachixPush =
        if cachixTokenPath != "" then
          "nix path-info -r /run/current-system | env CACHIX_AUTH_TOKEN=$(cat ${cachixTokenPath}) cachix push ${cName}"
        else
          "nix path-info -r /run/current-system | cachix push ${cName}";

      # Run a command string under POSIX `sh -c` so its operators (&&, |, $(),
      # env VAR=val, ;) are parsed by /bin/sh, never the user's interactive
      # shell. This makes every cache command behave identically under bash, zsh
      # and fish, which otherwise disagree on `&&` vs `; and`, `{ }` vs
      # `begin..end`, and the `VAR=val cmd` prefix.
      shc = script: "sh -c ${lib.escapeShellArg script}";

      # Standalone aliases: push one cache, no rebuild, errors surface to the user.
      atticPushAlias = shc atticPush;
      cachixPushAlias = shc cachixPush;

      # sw-style wrapper: rebuild first, then - only if it succeeded - push to
      # every enabled cache. Each push is isolated with `|| true` so one cache
      # failing never aborts the other, while the rebuild's exit status still
      # gates whether any push runs (the whole block lives behind one `&&`).
      wrapCaches =
        cmd:
        let
          pushLines =
            (lib.optional atticEnabled "${atticPush} || true")
            ++ (lib.optional cachixEnabled "${cachixPush} || true");
        in
        if pushLines == [ ] then cmd
        else "${cmd} && ${shc (lib.concatStringsSep "; " pushLines)}";

      nixosSwitchWrapped = wrapCaches nixosSwitchCmd;
      nixosUpdateWrapped = wrapCaches nixosUpdateCmd;
      nixosBootWrapped = wrapCaches nixosBootCmd;

      darwinSwitchCmd = "nh darwin switch ${flakeDir}";
      darwinUpdateCmd = "nix flake update && nh darwin switch ${flakeDir}";

      darwinSwitchWrapped = wrapCaches darwinSwitchCmd;
      darwinUpdateWrapped = wrapCaches darwinUpdateCmd;

      commonAliases = {
        cleanup = "nix-sweep -p default system";
        cleanup-ask = "nix-sweep -p ask system";
        dedup = "nix store optimise";
        cg = "nix-collect-garbage -d";
        nix-gc-roots = "nix-store --gc --print-roots";
        deadnixfixall = "nix run github:astro/deadnix -- -e ${flakeDir}";
        deadnixscanall = "nix run github:astro/deadnix -- ${flakeDir}";

        fmt-dry = "cd ${flakeDir} && git add -A && nix fmt -- --check";
        fmt = "cd ${flakeDir} && git add -A && nix fmt -- **/*.nix";
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop";
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop";
        cdnix = "cd ${flakeDir}";

        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "${safeEditor} $(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s";
        tksession = "tmux kill-session -t";
        tks = "tmux kill-server";

        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml";
        sops-common = "cd ${flakeDir}/users/${myconfig.constants.user}/common/sops && sops ${myconfig.constants.user}-common-secrets-sops.yaml";
        sops-host = "cd ${flakeDir} && sops hosts/${myconfig.constants.hostname}/${myconfig.constants.hostname}-secrets-sops.yaml";
      };

      nixosAliases = {
        swboot = "cd ${flakeDir} && git add -A && ${nixosBootWrapped}";
        swtest = "cd ${flakeDir} && git add -A && ${nixosTestCmd}";
        swdry = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir} --dry";
        sw = "cd ${flakeDir} && git add -A && ${nixosSwitchWrapped}";
        swfall = "cd ${flakeDir} && git add -A && ${wrapCaches "${nixosSwitchCmd} --fallback"}";
        gsw = "cd ${flakeDir} && git add -A && ${nixosSwitchWrapped}";
        gswfall = "cd ${flakeDir} && git add -A && ${wrapCaches "${nixosSwitchCmd} --fallback"}";
        gswoff = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir} -- --offline";
        swsrc = "cd ${flakeDir} && git add -A && ${wrapCaches "${nixosSwitchCmd} --option substitute false"}";
        swoff = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir} -- --offline";
        tswsrc = "cd ${flakeDir} && git add -A && time ${wrapCaches "${nixosSwitchCmd} --option substitute false"}";

        nfc = "cd ${flakeDir} && git add -A && nix flake check";
        nfcall = "cd ${flakeDir} && git add -A && nix flake check --all-systems";
        upd = "cd ${flakeDir} && git add -A && ${nixosUpdateWrapped}";

        swpure = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && git add -A && sudo nixos-rebuild switch --flake . --impure";

        pkgs-home = "$EDITOR ${flakeDir}/modules/${
          if isDarwin then "darwin/toplevel/home-packages-darwin.nix" else "nixos/toplevel/home-packages-nixos.nix"
        }";
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/local-packages.nix";

        se = "sudoedit";
        reb-uefi = "systemctl reboot --firmware-setup";
      }
      // (lib.optionalAttrs atticEnabled { attic-push = atticPushAlias; })
      // (lib.optionalAttrs cachixEnabled { cachix-push = cachixPushAlias; });

      homeAliases = {
        # -b hm-backup: standalone home-manager has no equivalent of the
        # NixOS/darwin-integration `home-manager.backupFileExtension` option
        # (that option only exists in the nixos/nix-darwin integration
        # layer), so activation backups have to be requested per-invocation
        # via the CLI flag instead. "hm-backup" matches the extension string
        # used by the darwin integration (see darwinAliases below) for
        # consistency across the repo.
        sw = "cd ${flakeDir} && git add -A && home-manager switch -b hm-backup --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        swdry = "cd ${flakeDir} && git add -A && home-manager build --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        upd = "cd ${flakeDir} && git add -A && nix flake update && home-manager switch -b hm-backup --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        hm-gens = "home-manager generations";
        nfc = "cd ${flakeDir} && git add -A && nix flake check";
      };

      darwinAliases = {
        sw = "cd ${flakeDir} && git add -A && ${darwinSwitchWrapped}";
        swfall = "cd ${flakeDir} && git add -A && ${wrapCaches "${darwinSwitchCmd} --fallback"}";
        gsw = "cd ${flakeDir} && git add -A && ${darwinSwitchWrapped}";
        gswfall = "cd ${flakeDir} && git add -A && ${wrapCaches "${darwinSwitchCmd} --fallback"}";
        swdry = "cd ${flakeDir} && git add -A && nh darwin switch ${flakeDir} --dry";
        gswoff = "cd ${flakeDir} && git add -A && nh darwin switch ${flakeDir} -- --offline";

        nfc = "cd ${flakeDir} && git add -A && nix flake check --impure";
        upd = "cd ${flakeDir} && git add -A && ${darwinUpdateWrapped}";

        brew-upd = "brew update && brew upgrade";
        brew-upd-res = "brew update-reset";
        brew-inst = "brew install";
        brew-inst-cask = "brew install --cask";
        brew-search = "brew search";
        brew-clean = "brew cleanup";

        caff = "caffeinate";
        xcodeaccept = "sudo xcodebuild -license accept";
        changehosts = "sudo nvim /etc/hosts";
        cleardns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
      }
      // (lib.optionalAttrs atticEnabled { attic-push = atticPushAlias; })
      // (lib.optionalAttrs cachixEnabled { cachix-push = cachixPushAlias; });
    in
    {
      home.packages = [ npu ];

      home.shellAliases = commonAliases
        // (if isNixOS then nixosAliases else { })
        // (if isDarwin then darwinAliases else { })
        // (if isHome then homeAliases else { })
        // lib.optionalAttrs (myconfig.services.snapshots.enable or false) (
        let
          hasImpermanence = myconfig.services.impermanence.enable or false;
          rootConfigName = if hasImpermanence then "persist" else "root";
        in
        {
          snap-list-home = "snapper -c home list";
          snap-list-root = "sudo snapper -c ${rootConfigName} list";
        }
      );
    };
}
