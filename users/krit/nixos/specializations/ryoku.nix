{ delib
, inputs
, pkgs
, config
, options
, lib
, ...
}:
let
  c = config.myconfig.constants;
  polarity = c.theme.polarity;
  capPolarity = lib.toUpper (lib.substring 0 1 polarity) + lib.substring 1 (-1) polarity;
  dotfilesUrl = "https://github.com/nicolkrit999/dotfiles";
  nixRepoUrl = "https://github.com/nicolkrit999/nix";
  dotfilesPrivateUrl = "ssh://git@gitea-ssh.nicolkrit.ch:2222/krit/dotfiles-private.git";
  giteaKnownHost = "[gitea-ssh.nicolkrit.ch]:2222 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";

  mkOff = paths: lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) paths
    )
  );

  # Full working copy at ~/<dir>: clone when missing, otherwise fast-forward only a clean, fully pushed
  # checkout. Never resets or discards (the user commits here, and Claude writes memory through the
  # dotfiles-private links). A shallow single-branch checkout from an older clone is healed first.
  # sshKey: private repo over SSH with that key and the pinned Gitea host key on port 2222; null: public https.
  mkRepoSync = pkgs: { name, description, dir, url, sshKey ? null }:
    let
      git = "${pkgs.git}/bin/git";
      coreutils = "${pkgs.coreutils}/bin";
      knownHosts = pkgs.writeText "ryoku-gitea-known-hosts" "${giteaKnownHost}\n";
    in
    {
      Unit = {
        Description = description;
        StartLimitIntervalSec = 0;
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "30s";
        Environment = [ "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" ];
        ExecStart = pkgs.writeShellScript name ''
          set -u
          dir="$HOME/${dir}"
          export GIT_TERMINAL_PROMPT=0
          ${lib.optionalString (sshKey != null) ''
            key="$HOME/${sshKey}"
            if [ ! -r "$key" ]; then
              echo "${name}: $key is not readable yet" >&2
              exit 1
            fi
            export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${knownHosts}"
          ''}
          if [ -d "$dir/.git" ]; then
            if [ "$(${git} -C "$dir" rev-parse --is-shallow-repository)" = true ]; then
              ${git} -C "$dir" fetch --quiet --unshallow origin || exit 1
            fi
            ${git} -C "$dir" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
            ${git} -C "$dir" fetch --quiet origin || exit 1
            if [ -n "$(${git} -C "$dir" status --porcelain)" ]; then
              echo "${name}: work tree has local changes, not updating" >&2
              exit 0
            fi
            ahead=$(${git} -C "$dir" rev-list --count '@{u}..HEAD' 2>/dev/null) || exit 0
            if [ "$ahead" != 0 ]; then
              echo "${name}: unpushed commits, not updating" >&2
              exit 0
            fi
            ${git} -C "$dir" merge --quiet --ff-only '@{u}' || exit 1
          elif [ -e "$dir" ]; then
            echo "${name}: $dir exists but is not a git checkout, leaving it alone" >&2
            exit 1
          else
            tmp=$(${coreutils}/mktemp -d "$HOME/.${name}.XXXXXX")
            trap '${coreutils}/rm -rf "$tmp"' EXIT
            ${git} clone --quiet ${url} "$tmp/repo" || exit 1
            [ -e "$dir" ] || ${coreutils}/mv "$tmp/repo" "$dir"
          fi
        '';
      };
    };

  personalOff = mkOff [
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
  ];

  hasPath = path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options;
in
delib.module {
  name = "krit.specializations.ryoku";

  nixos.always = lib.mkIf config.myconfig.specializations.ryoku.enable {
    myconfig.specializations.ryoku.fastfetchEmblem =
      "${inputs.ryoku.packages.${pkgs.stdenv.hostPlatform.system}.ryoku-desktop-data}/share/ryoku/ryodecors/hawk.png";

    myconfig.specializations.ryoku.sddmCursorTheme = "Bibata-Modern-Ice";
    myconfig.specializations.ryoku.sddmCursorPackage = pkgs.bibata-cursors;

    myconfig.specializations.ryoku.settings = {
      desktop = {
        desktop.appearance = {
          gapsIn = 6;
          gapsOut = 12;
          rounding = 4;
        };
        desktop.input = {
          middleEmulation = true;
          workspaceSwipe = true;
        };
        wm.hyprland.dwindle.preserveSplit = true;
      };
      shell = {
        fontFamily = "JetBrainsMono Nerd Font Mono";
        deckFrost = 0.5;
        barStyle = "orpheus";
        clipboard.pruneWeekly = true;
        general.temperature_unit = "Metric";
        theme = {
          theme = "Dracula";
          matugen = {
            contrast = 0;
            mode = capPolarity;
            preference = "Darkness";
            scheme_type = "Expressive";
          };
        };
      };
      launcher = {
        bgBlur = 8;
        heroStrength = 0.3786;
        showGreeting = false;
        heroImage = "file://${config.myconfig.specializations.ryoku.home}/Pictures/Wallpapers/wallhaven-vpyrm5.jpg";
      };
      matugen = {
        mode = polarity;
        schemeType = "scheme-expressive";
        contrast = 0;
        prefer = "darkness";
      };
      ryogami = {
        theme = {
          policy = "fixed";
          staticTheme = "Dracula";
        };
        matugen.mode = polarity;
        wallpaperMute = true;
        transition = {
          durationMs = 900;
          enabled = true;
          shader = "random";
        };
        overviewBackdrop = {
          blur = 45;
          blurEnabled = true;
          dim = 0;
          enabled = true;
          followWallpaper = true;
        };
        components.wallpaperSelector.displayMode = "slices";
      };
    };

    specialisation.ryoku.configuration = { config, ... }:
      let
        user = config.myconfig.constants.user;
      in
      {
        imports = [
          personalOff
          (lib.optionalAttrs (hasPath [ "services" "external" "dotfiles" "wallpapersLink" ]) {
            myconfig.services.external.dotfiles.wallpapersLink = lib.mkForce false;
          })
          (lib.optionalAttrs (hasPath [ "krit" "programs" "yazi" "goToExclude" ]) {
            myconfig.krit.programs.yazi.goToExclude = [ "M" ];
          })
        ];

        home-manager.users.${user} = { pkgs, ... }: {
          systemd.user.services = {
            ryoku-dotfiles-sync = mkRepoSync pkgs {
              name = "ryoku-dotfiles-sync";
              description = "Clone or update the public dotfiles into ~/dotfiles (nvim config link target)";
              dir = "dotfiles";
              url = dotfilesUrl;
            };
            ryoku-dotfiles-private-sync = mkRepoSync pkgs {
              name = "ryoku-dotfiles-private-sync";
              description = "Clone or fast-forward the private dotfiles into ~/dotfiles-private (Claude config and memory links)";
              dir = "dotfiles-private";
              url = dotfilesPrivateUrl;
              sshKey = ".ssh/id_github";
            };
            ryoku-nix-sync = mkRepoSync pkgs {
              name = "ryoku-nix-sync";
              description = "Clone or update the public nix repo into ~/${c.flakeDir}";
              dir = c.flakeDir;
              url = nixRepoUrl;
            };
          };
        };
      };
  };
}
