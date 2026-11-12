{ delib
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
  repoBranch = "main";

  mkOff = paths: lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) paths
    )
  );

  personalOff = mkOff [
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
  ];

  hasPath = path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options;

  # Read-only mirror of a public repo at ~/<dir>: clone when missing, otherwise fetch and hard-reset.
  mkRepoSync = pkgs: { name, description, dir, url }: {
    Unit = {
      Description = description;
      StartLimitIntervalSec = 0;
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "30s";
      Environment = [
        "GIT_TERMINAL_PROMPT=0"
        "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt"
      ];
      ExecStart = pkgs.writeShellScript name ''
        set -eu
        dir="$HOME/${dir}"
        if [ -d "$dir/.git" ]; then
          ${pkgs.git}/bin/git -C "$dir" fetch --quiet --depth 1 origin ${repoBranch}
          ${pkgs.git}/bin/git -C "$dir" reset --quiet --hard FETCH_HEAD
        elif [ -e "$dir" ]; then
          echo "${name}: $dir exists but is not a git checkout, leaving it alone" >&2
          exit 1
        else
          tmp=$(${pkgs.coreutils}/bin/mktemp -d "$HOME/.${name}.XXXXXX")
          trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
          ${pkgs.git}/bin/git clone --quiet --depth 1 --branch ${repoBranch} ${url} "$tmp/repo"
          [ -e "$dir" ] || ${pkgs.coreutils}/bin/mv "$tmp/repo" "$dir"
        fi
      '';
    };
  };
in
delib.module {
  name = "krit.specializations.ryoku";

  nixos.always = lib.mkIf config.myconfig.specializations.ryoku.enable {
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
