{ delib, lib, moduleSystem, ... }:
delib.module {
  name = "programs.shell-aliases";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    let
      flakeDir = "~/nixOS";
      safeEditor = myconfig.constants.editor;
      isImpure = myconfig.constants.nixImpure or false;
      isNixOS = moduleSystem == "nixos";
      isDarwin = moduleSystem == "darwin";

      # =========================================================================
      # NIXOS-SPECIFIC COMMAND BUILDERS
      # =========================================================================
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
          "nh os boot --update ${flakeDir}";

      wrapCachix =
        cmd:
        if (myconfig.cachix.enable or false) && (myconfig.cachix.push or false) then
          let
            cName =
              if myconfig.cachix.name == "use-constant" then
                myconfig.constants.cachix.name
              else
                myconfig.cachix.name;
          in
          "${cmd}; and nix path-info -r /run/current-system | cachix push ${cName}"
        else
          cmd;

      nixosSwitchWrapped = wrapCachix nixosSwitchCmd;
      nixosUpdateWrapped = wrapCachix nixosUpdateCmd;
      nixosBootWrapped = wrapCachix nixosBootCmd;

      # =========================================================================
      # DARWIN-SPECIFIC COMMAND BUILDERS
      # =========================================================================
      darwinSwitchCmd = "nh darwin switch ${flakeDir}";
      darwinUpdateCmd = "nix flake update && nh darwin switch ${flakeDir}";

      # =========================================================================
      # COMMON ALIASES (both NixOS and Darwin)
      # =========================================================================
      commonAliases = {
        # Nix maintenance
        dedup = "nix store optimise";
        cg = "nix-collect-garbage -d";
        deadnixfixall = "nix run github:astro/deadnix -- -e ${flakeDir}";
        deadnixscanall = "nix run github:astro/deadnix -- ${flakeDir}";

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check";
        fmt = "cd ${flakeDir} && nix fmt -- **/*.nix";
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop";
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop";
        cdnix = "cd ${flakeDir}";
        nfc = "cd ${flakeDir} && nix flake check";
        nfcall = "cd ${flakeDir} && nix flake check --all-systems";

        # Utilities
        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "${safeEditor} $(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s";
        tksession = "tmux kill-session -t";
        tks = "tmux kill-server";

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml";
        sops-common = "cd ${flakeDir}/users/${myconfig.constants.user}/sops && sops ${myconfig.constants.user}-common-secrets-sops.yaml";
        sops-host = "cd ${flakeDir} && sops hosts/${myconfig.constants.hostname}/${myconfig.constants.hostname}-secrets-sops.yaml";
      };

      # =========================================================================
      # NIXOS-SPECIFIC ALIASES
      # =========================================================================
      nixosAliases = {
        # Switch commands
        sw = "cd ${flakeDir} && ${nixosSwitchWrapped}";
        swsrc = "cd ${flakeDir} && ${nixosSwitchWrapped} --option substitute false";
        tswsrc = "cd ${flakeDir} && time ${nixosSwitchWrapped} --option substitute false";
        swoff = "cd ${flakeDir} && ${nixosSwitchCmd} --offline";
        gsw = "cd ${flakeDir} && git add -A && ${nixosSwitchWrapped}";
        gswoff = "cd ${flakeDir} && git add -A && ${nixosSwitchCmd} --offline";
        upd = "cd ${flakeDir} && ${nixosUpdateWrapped}";
        swdry = "cd ${flakeDir} && nh os test --dry --ask";
        swboot = "cd ${flakeDir} && ${nixosBootWrapped}";

        # Manual commands for reference
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # System maintenance (NixOS-specific)
        cleanup = "nh clean all";
        cleanup-ask = "nh clean all --ask";

        # Pkgs editing
        pkgs-home = "$EDITOR ${flakeDir}/home-manager/home-packages.nix";
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/optional/host-packages/local-packages.nix";

        # Snapshots (snapper)
        snap-list-home = "snapper -c home list";
        snap-list-root = "sudo snapper -c root list";

        # System utilities
        se = "sudoedit";
        reb-uefi = "systemctl reboot --firmware-setup";
        swdryaarch64-linux = "nix build ${flakeDir}#nixosConfigurations.nixos-arm-vm.config.system.build.toplevel --dry-run --show-trace";
      };

      # =========================================================================
      # DARWIN-SPECIFIC ALIASES
      # =========================================================================
      darwinAliases = {
        # Switch commands
        sw = "cd ${flakeDir} && ${darwinSwitchCmd}";
        gsw = "cd ${flakeDir} && git add -A && ${darwinSwitchCmd}";
        upd = "cd ${flakeDir} && ${darwinUpdateCmd}";
        swdry = "cd ${flakeDir} && nh darwin switch --dry ${flakeDir}";

        # Homebrew
        brew-upd = "brew update && brew upgrade";
        brew-upd-res = "brew update-reset";
        brew-inst = "brew install";
        brew-inst-cask = "brew install --cask";
        brew-search = "brew search";
        brew-clean = "brew cleanup";

        # macOS utilities
        caff = "caffeinate";
        xcodeaccept = "sudo xcodebuild -license accept";
        changehosts = "sudo nvim /etc/hosts";
        cleardns = "sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder";
      };
    in
    {
      home.shellAliases = commonAliases
        // (if isNixOS then nixosAliases else {})
        // (if isDarwin then darwinAliases else {});
    };
}
