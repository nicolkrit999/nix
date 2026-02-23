{ delib, ... }:
delib.module {
  name = "programs.shell-aliases";
  options = delib.singleEnableOption true;

  # Always enabled
  home.ifEnabled = { myconfig, ... }:
    let
      flakeDir = "~/nixOS";
      safeEditor = myconfig.constants.editor;
      isImpure = myconfig.constants.nixImpure;

      baseSwitchCmd =
        if isImpure then "sudo nixos-rebuild switch --flake . --impure"
        else "nh os switch ${flakeDir}";


      baseUpdateCmd =
        if isImpure then
          "nix flake update && sudo nixos-rebuild switch --flake . --impure"
        else
          "nh os switch --update ${flakeDir}";

      baseBootCmd =
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

      # wrappped commands
      switchCmd = wrapCachix baseSwitchCmd;
      updateCmd = wrapCachix baseUpdateCmd;
      updateBoot = wrapCachix baseBootCmd;
    in
    {
      home.shellAliases = {

        # Smart aliases based on nixImpure setting
        sw = "cd ${flakeDir} && ${switchCmd}";
        swsrc = "cd ${flakeDir} && ${switchCmd} --option substitute false";
        tswsrc = "cd ${flakeDir} && time ${switchCmd} --option substitute false";
        swoff = "cd ${flakeDir} && ${baseSwitchCmd} --offline";
        gsw = "cd ${flakeDir} && git add -A && ${switchCmd}";
        gswoff = "cd ${flakeDir} && git add -A && ${baseSwitchCmd} --offline";
        upd = "cd ${flakeDir} && ${updateCmd}";

        # Manual are kept for reference, but use the above aliases instead
        swpure = "cd ${flakeDir} && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && sudo nixos-rebuild switch --flake . --impure";

        # System maintenance
        dedup = "nix store optimise";
        cleanup = "nh clean all";
        cleanup-ask = "nh clean all --ask";
        cg = "nix-collect-garbage -d";

        # Home-Manager related (). Currently disabled because "sw" handle also home manager. Kept for reference
        # hms = "cd ${flakeDir} && home-manager switch --flake ${flakeDir}#${myconfig.constants.hostname}"; # Rebuild home-manager config

        # Pkgs editing
        pkgs-home = "$EDITOR ${flakeDir}/home-manager/home-packages.nix"; # Edit home-manager packages list
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/optional/host-packages/local-packages.nix"; # Edit host-specific packages list

        # Nix repo management
        fmt-dry = "cd ${flakeDir} && nix fmt -- --check"; # Check formatting without making changes (list files that need formatting)
        fmt = "cd ${flakeDir} &&  nix fmt -- **/*.nix"; # Format Nix files using nixfmt (a regular nix fmt hangs on zed theme)
        merge_dev-main = "cd ${flakeDir} && git stash && git checkout main && git pull origin main && git merge develop && git push; git checkout develop && git stash pop"; # Merge main with develop branch, push and return to develop branch
        merge_main-dev = "cd ${flakeDir} && git stash && git checkout develop && git pull origin develop && git merge main && git push; git checkout develop && git stash pop"; # Merge develop with main branch, push and return to develop branch
        cdnix = "cd ${flakeDir}";
        nfc = "cd ${flakeDir} && nix flake check"; # Check flake for errors
        nfcall = "cd ${flakeDir} && nix flake check --all-systems"; # Check flake for errors (all hosts)
        swdry = "cd ${flakeDir} && nh os test --dry --ask"; # Dry run of nixos-rebuild switch

        # Snapshots
        snap-list-home = "snapper -c home list"; # List home snapshots
        snap-list-root = "sudo snapper -c root list"; # List root snapshots

        # Utilities
        se = "sudoedit";
        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "${safeEditor} $(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s"; # List all zoxide entries with scores
        tksession = "tmux kill-session -t"; # Kill a tmux session by name
        tks = "tmux kill-server"; # Kill all tmux sessions

        # Sops secrets editing
        sops-main = "cd ${flakeDir} && $EDITOR .sops.yaml"; # Edit main sops config
        sops-common = "cd ${flakeDir}/common/${myconfig.constants.user}/sops && sops ${myconfig.constants.user}-common-secrets-sops.yaml"; # Edit sops secrets file
        sops-host = "cd ${flakeDir} && sops hosts/${myconfig.constants.hostname}/optional/host-sops-nix/${myconfig.constants.hostname}-secrets-sops.yaml"; # Edit host-specific sops secrets file

        # Various
        reb-uefi = "systemctl reboot --firmware-setup"; # Reboot into UEFI firmware settings
        swboot = "cd ${flakeDir} && ${updateBoot}"; # Rebuilt boot without crash current desktop environment
      };
    };
}
