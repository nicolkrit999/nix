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

      tpmReenroll = pkgs.writeShellScriptBin "tpm-reenroll" ''
        set -euo pipefail
        pcrs="0+2+7"
        mappers=$(${pkgs.util-linux}/bin/lsblk -rno NAME,TYPE \
          | ${pkgs.gawk}/bin/awk '$2=="crypt"{print $1}')
        if [ -z "$mappers" ]; then
          echo "No active LUKS/crypt devices found - nothing to do."
          exit 0
        fi
        sudo -v
        for name in $mappers; do
          dev=$(sudo ${pkgs.cryptsetup}/bin/cryptsetup status "$name" \
            | ${pkgs.gawk}/bin/awk '/device:/{print $2}')
          [ -z "$dev" ] && { echo "Could not resolve backing device for '$name', skipping."; continue; }
          echo "Re-enrolling TPM2 (PCRs $pcrs) for $name -> $dev"
          sudo ${pkgs.systemd}/bin/systemd-cryptenroll --wipe-slot=tpm2 "$dev" || true
          sudo ${pkgs.systemd}/bin/systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs="$pcrs" "$dev"
        done
        echo "Done. Reboot to confirm auto-unlock."
      '';

      flakeDir = "~/${myconfig.constants.flakeDir}";
      isImpure = myconfig.constants.nixImpure;
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";
      isHome = moduleSystem == "home";

      rebuild =
        verb: if isImpure then "sudo nixos-rebuild ${verb} --flake . --impure" else "nh os ${verb} ${flakeDir}";

      nixosSwitchCmd = rebuild "switch";
      nixosBootCmd = rebuild "boot";
      nixosTestCmd = rebuild "test";

      nixosUpdateCmd =
        if isImpure then
          "nix flake update && sudo nixos-rebuild switch --flake . --impure"
        else
          "nh os switch --update ${flakeDir}";

      nixosDryCmd =
        if isImpure then
          "nixos-rebuild dry-build --flake . --impure"
        else
          "nh os switch ${flakeDir} --dry";

      nixosOfflineCmd =
        if isImpure then
          "sudo nixos-rebuild switch --flake . --impure --offline"
        else
          "nh os switch ${flakeDir} -- --offline";

      atticEnabled = myconfig.attic.enable && myconfig.attic.push;
      cachixEnabled = myconfig.cachix.enable && myconfig.cachix.push;

      currentSystem = "/run/current-system";
      systemProfile = "/nix/var/nix/profiles/system";

      atticCache = myconfig.attic.cacheName;
      atticPush =
        path: "nix path-info -r ${path} | attic push -j 8 nas-push:${atticCache} --stdin";

      cName = myconfig.cachix.name;
      cachixTokenPath = myconfig.cachix.authTokenPath;
      cachixPush =
        path:
        if cachixTokenPath != "" then
          "nix path-info -r ${path} | CACHIX_AUTH_TOKEN=\"$(cat ${cachixTokenPath})\" cachix push ${cName}"
        else
          "nix path-info -r ${path} | cachix push ${cName}";

      shc = script: "sh -c ${lib.escapeShellArg script}";

      pushAliases =
        lib.optionalAttrs atticEnabled { attic-push = shc (atticPush currentSystem); }
        // lib.optionalAttrs cachixEnabled { cachix-push = shc (cachixPush currentSystem); };

      wrapCaches =
        path: cmd:
        let
          pushLines =
            (lib.optional atticEnabled "${atticPush path} || true")
            ++ (lib.optional cachixEnabled "${cachixPush path} || true");
        in
        if pushLines == [ ] then cmd
        else "${cmd} && ${shc (lib.concatStringsSep "; " pushLines)}";

      wrapCurrent = wrapCaches currentSystem;

      nixosSwitchWrapped = wrapCurrent nixosSwitchCmd;
      nixosUpdateWrapped = wrapCurrent nixosUpdateCmd;
      nixosBootWrapped = wrapCaches systemProfile nixosBootCmd;

      darwinRebuildCmd = "sudo darwin-rebuild switch --flake .#${myconfig.constants.hostname} --impure";

      darwinSwitchCmd =
        if isImpure then darwinRebuildCmd else "nh darwin switch ${flakeDir}";
      darwinUpdateCmd =
        if isImpure then
          "nix flake update && ${darwinRebuildCmd}"
        else
          "nix flake update && nh darwin switch ${flakeDir}";
      darwinDryCmd =
        if isImpure then
          "darwin-rebuild build --flake .#${myconfig.constants.hostname} --impure --dry-run"
        else
          "nh darwin switch ${flakeDir} --dry";
      darwinOfflineCmd =
        if isImpure then "${darwinRebuildCmd} --offline" else "nh darwin switch ${flakeDir} -- --offline";

      darwinSwitchWrapped = wrapCurrent darwinSwitchCmd;
      darwinUpdateWrapped = wrapCurrent darwinUpdateCmd;

      commonAliases = {
        dedup = "nix store optimise";
        cg = "nix-collect-garbage -d";
        nix-gc-roots = "nix-store --gc --print-roots";
        deadnixfixall = "nix run github:astro/deadnix -- -e ${flakeDir}";
        deadnixscanall = "nix run github:astro/deadnix -- ${flakeDir}";

        fmt-dry = "cd ${flakeDir} && git add -A && nix fmt -- --check";
        fmt = "cd ${flakeDir} && git add -A && nix fmt";
        cdnix = "cd ${flakeDir}";

        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "fzf -m --print0 --preview='cat {}' | xargs -0 -r -o $EDITOR";
        zlist = "zoxide query -l -s";

        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml";
        sops-common = "cd ${flakeDir}/users/${myconfig.constants.user}/common/sops && sops ${myconfig.constants.user}-common-secrets-sops.yaml";
        sops-host = "cd ${flakeDir} && sops hosts/${myconfig.constants.hostname}/${myconfig.constants.hostname}-secrets-sops.yaml";
      }
      // lib.optionalAttrs myconfig.nix-sweeps.enable {
        cleanup = "nix-sweep -p default system";
        cleanup-ask = "nix-sweep -p ask system";
      }
      // lib.optionalAttrs myconfig.programs.tmux.enable {
        tksession = "tmux kill-session -t";
        tks = "tmux kill-server";
      };

      nixosAliases = {
        su = "su -l";
        swboot = "cd ${flakeDir} && git add -A && ${nixosBootWrapped}";
        swtest = "cd ${flakeDir} && git add -A && ${nixosTestCmd}";
        swdry = "cd ${flakeDir} && git add -A && ${nixosDryCmd}";
        sw = "cd ${flakeDir} && ${nixosSwitchWrapped}";
        swfall = "cd ${flakeDir} && ${wrapCurrent "${nixosSwitchCmd} --fallback"}";
        gsw = "cd ${flakeDir} && git add -A && ${nixosSwitchWrapped}";
        gswfall = "cd ${flakeDir} && git add -A && ${wrapCurrent "${nixosSwitchCmd} --fallback"}";
        gswoff = "cd ${flakeDir} && git add -A && ${nixosOfflineCmd}";
        swsrc = "cd ${flakeDir} && git add -A && ${wrapCurrent "${nixosSwitchCmd} --option substitute false"}";
        swoff = "cd ${flakeDir} && ${nixosOfflineCmd}";
        tswsrc = "cd ${flakeDir} && git add -A && time ${wrapCurrent "${nixosSwitchCmd} --option substitute false"}";

        nfc = "cd ${flakeDir} && git add -A && nix flake check";
        nfcall = "cd ${flakeDir} && git add -A && nix flake check --all-systems";
        upd = "cd ${flakeDir} && git add -A && ${nixosUpdateWrapped}";

        swpure = "cd ${flakeDir} && git add -A && ${if myconfig.nh.enable then "nh os switch ${flakeDir}" else "sudo nixos-rebuild switch --flake ."}";
        swimpure = "cd ${flakeDir} && git add -A && sudo nixos-rebuild switch --flake . --impure";

        pkgs-home = "$EDITOR ${flakeDir}/modules/nixos/toplevel/home-packages-nixos.nix";
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/local-packages.nix";

        se = "sudoedit";
        reb-uefi = "systemctl reboot --firmware-setup";
      }
      // pushAliases;

      hmTarget = ".#${myconfig.constants.user}@${myconfig.constants.hostname}";
      hmImpure = lib.optionalString isImpure " --impure";

      homeAliases = {
        sw = "cd ${flakeDir} && home-manager switch -b hm-backup --flake ${hmTarget}${hmImpure}";
        gsw = "cd ${flakeDir} && git add -A && home-manager switch -b hm-backup --flake ${hmTarget}${hmImpure}";
        swdry = "cd ${flakeDir} && git add -A && home-manager build --flake ${hmTarget}${hmImpure}";
        upd = "cd ${flakeDir} && git add -A && nix flake update && home-manager switch -b hm-backup --flake ${hmTarget}${hmImpure}";
        hm-gens = "home-manager generations";
        nfc = "cd ${flakeDir} && git add -A && nix flake check${hmImpure}";
      };

      darwinAliases = {
        sw = "cd ${flakeDir} && ${darwinSwitchWrapped}";
        swfall = "cd ${flakeDir} && ${wrapCurrent "${darwinSwitchCmd} --fallback"}";
        gsw = "cd ${flakeDir} && git add -A && ${darwinSwitchWrapped}";
        gswfall = "cd ${flakeDir} && git add -A && ${wrapCurrent "${darwinSwitchCmd} --fallback"}";
        swdry = "cd ${flakeDir} && git add -A && ${darwinDryCmd}";
        gswoff = "cd ${flakeDir} && git add -A && ${darwinOfflineCmd}";

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
        changehosts = "sudo -e /etc/hosts";
        cleardns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";

        pkgs-home = "$EDITOR ${flakeDir}/modules/darwin/toplevel/home-packages-darwin.nix";
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/local-packages.nix";
      }
      // pushAliases;
    in
    {
      home.packages = [ npu ] ++ lib.optionals isNixOS [ tpmReenroll ];

      home.shellAliases = commonAliases
        // lib.optionalAttrs isNixOS nixosAliases
        // lib.optionalAttrs isDarwin darwinAliases
        // lib.optionalAttrs isHome homeAliases
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
