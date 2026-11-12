{ delib
, inputs
, config
, options
, lib
, pkgs
, ...
}:
let
  baseUser = config.myconfig.constants.user;
  baseCatppuccin = config.myconfig.constants.theme.catppuccin;
  ryokuUser = "${baseUser}-ryoku";
  ryokuHome = "/home/${ryokuUser}";
  ryokuUid = 1002;
  ryokuSubId = 231072;
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;
  portalConfig = import ../toplevel/xdg-portal-config.nix { inherit lib; };
  cfg = config.myconfig.specializations.ryoku;
  constants = config.myconfig.constants;
  inTerminal = app:
    if lib.elem app constants.terminalApps
    then "${constants.terminal.name} -e ${app}"
    else app;
  json = pkgs.formats.json { };
  firstEntry = s: lib.head (lib.splitString "," s);

  staticPolarity = {
    Dracula = "dark";
  };
  declaredStaticThemes = lib.filter (n: n != null) [
    (cfg.settings.shell.theme.theme or null)
    (cfg.settings.ryogami.theme.staticTheme or null)
  ];

  settingsStores = [
    "brand"
    "desktop"
    "equalizer"
    "fastfetch"
    "launcher"
    "matugen"
    "performance"
    "plugins"
    "power-profile"
    "ryogami"
    "shell"
    "stage"
    "stash"
    "theme"
    "visualizer"
    "widgets"
  ];
  secretStores = [ "hub" "i18n-llm" ];
  declaredSettings = lib.filterAttrs (_: v: v != { }) cfg.settings;
  hasSettings = declaredSettings != { };

  coreutils = "${pkgs.coreutils}/bin";
  jq = "${pkgs.jq}/bin/jq";
  flock = "${pkgs.util-linux}/bin/flock";

  seedCall = store: value:
    let
      decl = json.generate "ryoku-settings-${store}.json" value;
      hash = builtins.substring 0 16 (builtins.hashString "sha256" (builtins.toJSON { inherit value; }));
    in
    if store == "desktop"
    then ''{ ${flock} -x 9; seed ${store} ${decl} ${hash}; } 9>>"$cfg/.desktop.lock" || rc=1''
    else "seed ${store} ${decl} ${hash} || rc=1";

  settingsSeedScript = pkgs.writeShellScript "ryoku-settings-seed" ''
    set -u
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/ryoku"
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/ryoku/nix"
    mode=${cfg.settingsMode}
    rc=0
    ${coreutils}/mkdir -p "$cfg" "$state"

    seed() {
      store=$1 decl=$2 hash=$3
      file="$cfg/$store.json"
      sentinel="$state/settings-seeded-$store-$hash"
      if [ "$mode" = seed-once ] && [ -e "$sentinel" ]; then
        return 0
      fi
      tmp=$(${coreutils}/mktemp "$cfg/.tmp-seed.XXXXXX") || return 1
      if [ -e "$file" ]; then
        if ! ${jq} -e 'type == "object"' "$file" >/dev/null 2>&1; then
          echo "ryoku-settings-seed: $file is not a JSON object, left untouched" >&2
          ${coreutils}/rm -f "$tmp"
          return 1
        fi
        ${jq} --slurpfile d "$decl" '. * $d[0]' "$file" > "$tmp" || { ${coreutils}/rm -f "$tmp"; return 1; }
        ${coreutils}/chmod --reference="$file" "$tmp"
      else
        ${jq} . "$decl" > "$tmp" || { ${coreutils}/rm -f "$tmp"; return 1; }
        ${coreutils}/chmod 0644 "$tmp"
      fi
      ${coreutils}/mv -f "$tmp" "$file" || { ${coreutils}/rm -f "$tmp"; return 1; }
      if [ "$mode" = seed-once ]; then
        ${coreutils}/rm -f "$state/settings-seeded-$store-"*
        : > "$sentinel"
      fi
    }

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList seedCall declaredSettings)}
    exit "$rc"
  '';

  hub = "${inputs.ryoku.packages.${pkgs.stdenv.hostPlatform.system}.ryoku-hub}/bin/ryoku-hub";
  emblemHash = builtins.substring 0 16 (builtins.hashString "sha256" "${cfg.fastfetchEmblem}");

  fastfetchEmblemScript = pkgs.writeShellScript "ryoku-fastfetch-emblem-seed" ''
    set -u
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/ryoku/nix"
    sentinel="$state/fastfetch-emblem-${emblemHash}"
    ${coreutils}/mkdir -p "$state"
    if [ -e "$sentinel" ]; then
      exit 0
    fi
    logo=$(${hub} fastfetch import-logo ${cfg.fastfetchEmblem}) || {
      echo "ryoku-fastfetch-emblem-seed: import-logo failed, will retry next login" >&2
      exit 0
    }
    model=$(${hub} fastfetch get | ${jq} -c --arg p "$logo" '.logo.kind = "image" | .logo.source = $p | .logo.dither = false') || {
      echo "ryoku-fastfetch-emblem-seed: reading the fastfetch model failed, will retry next login" >&2
      exit 0
    }
    ${hub} fastfetch save "$model" >/dev/null || {
      echo "ryoku-fastfetch-emblem-seed: saving the fastfetch config failed, will retry next login" >&2
      exit 0
    }
    ${coreutils}/rm -f "$state/fastfetch-emblem-"*
    : > "$sentinel"
  '';

  stylixLiteOn = [ "bat" "blender" "cava" "fzf" "gdu" "gedit" "lazygit" "nixcord" "tmux" "zathura" "zen-browser" ];
  stylixLiteOff = [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" ];

  yaziUserConfig = cf: pkgs.linkFarm "yazi-user-config" (lib.mapAttrsToList
    (n: e: { name = lib.removePrefix "yazi/" n; path = e.source; })
    (lib.filterAttrs (n: e: lib.hasPrefix "yazi/" n && (e.enable || n == "yazi/yazi.toml")) cf));

  mkOff = paths: lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) paths
    )
  );

  desktopsOff = mkOff [
    [ "programs" "cosmic" ]
    [ "programs" "gnome" ]
    [ "programs" "hyprland" ]
    [ "programs" "kde" ]
    [ "programs" "mango" ]
    [ "programs" "niri" ]
    [ "bluetooth" ]
    [ "qt" ]
    [ "programs" "caelestia" ]
    [ "programs" "fastfetch" ]
    [ "programs" "noctalia" ]
    [ "programs" "skwdWall" ]
    [ "programs" "starship" ]
    [ "programs" "swayosd" ]
    [ "programs" "vicinae" ]
    [ "programs" "walker" ]
    [ "programs" "waybar-hyprland" ]
    [ "programs" "waybar-mango" ]
    [ "programs" "waybar-niri" ]
    [ "services" "auto-cpufreq" ]
    [ "services" "coffee" ]
    [ "services" "hypridle" ]
    [ "services" "sddm-astronaut" ]
    [ "services" "sddm-pixie" ]
    [ "services" "swaync" ]
    [ "services" "tlp" ]
  ];
in
delib.module {
  name = "specializations.ryoku";
  options = delib.moduleOptions {
    enable = delib.boolOption false;
    user = lib.mkOption {
      type = lib.types.str;
      default = ryokuUser;
      readOnly = true;
      description = "User of the Ryoku specialization.";
    };
    home = lib.mkOption {
      type = lib.types.str;
      default = ryokuHome;
      readOnly = true;
      description = "Home directory of the Ryoku specialization user.";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf json.type;
      default = { };
      description = ''
        Declared Ryoku settings, keyed by store (the JSON file name without
        extension under ~/.config/ryoku). Each value is deep-merged over the
        user's existing store by the ryoku-settings-seed user service. Empty
        generates nothing. Secret stores (hub, i18n-llm) and
        python.general.location in shell are rejected.
      '';
    };
    fastfetchEmblem = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Image used as the Ryoku fastfetch emblem, applied through the Hub's own
        import (copied to ~/.config/fastfetch/ryoku-logo.<ext>, config.jsonc
        repointed, layout kept) by the ryoku-fastfetch-emblem-seed user service.
        Applied once per declared path; Hub choices survive until the path
        changes. Null does nothing. The logo type stays the one in config.jsonc
        (kitty-direct needs kitty or ghostty).
      '';
    };
    sddmCursorTheme = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Cursor theme for the SDDM greeter in the Ryoku entry. The nixpkgs SDDM
        module only sets a cursor for the breeze theme, and the spec has no
        KDE, so without this the greeter has no cursor theme to load. Null
        leaves the greeter settings untouched.
      '';
    };
    sddmCursorPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Package providing sddmCursorTheme, installed system-wide so the greeter finds it under /run/current-system/sw/share/icons.";
    };
    sddmCursorSize = lib.mkOption {
      type = lib.types.ints.positive;
      default = 24;
      description = "Cursor size for the SDDM greeter.";
    };
    settingsMode = lib.mkOption {
      type = lib.types.enum [ "seed-once" "enforce" ];
      default = "seed-once";
      description = ''
        seed-once applies each store once per declaration (sentinel keyed on
        the declared content), so Hub edits to declared keys survive until the
        declaration changes. enforce re-applies the declaration on every login.
      '';
    };
  };

  nixos.always = {
    imports = [ inputs.ryoku.nixosModules.default ];
  };

  nixos.ifEnabled = {
    myconfig.specializations.ryoku.settings.desktop.desktop.apps = lib.mapAttrs (_: lib.mkDefault) {
      browser = constants.browser;
      terminal = constants.terminal.name;
      editor = inTerminal constants.editor;
      files = inTerminal constants.fileManager;
      notes = inTerminal constants.editor;
    };

    # Ryoku is single-layout (first entry only); the host's layout switching options do not apply.
    myconfig.specializations.ryoku.settings.desktop.desktop.input = lib.mapAttrs (_: lib.mkDefault) {
      kbLayout = firstEntry constants.keyboardLayout;
      kbVariant = firstEntry constants.keyboardVariant;
      kbOptions = "";
      naturalScroll = false;
    };

    assertions = [
      {
        assertion = lib.all (n: lib.elem n settingsStores) (lib.attrNames cfg.settings);
        message = "specializations.ryoku.settings: unknown store(s) ${toString (lib.subtractLists settingsStores (lib.attrNames cfg.settings))}; allowed: ${toString settingsStores}";
      }
      {
        assertion = lib.all (n: !(cfg.settings ? ${n})) secretStores;
        message = "specializations.ryoku.settings: stores ${toString secretStores} hold secrets or UI state and must not be declared (the repo is public)";
      }
      {
        assertion = !(lib.hasAttrByPath [ "python" "general" "location" ] (cfg.settings.shell or { }));
        message = "specializations.ryoku.settings.shell: python.general.location is volatile personal data and must not be declared";
      }
      {
        assertion = lib.all (n: (staticPolarity.${n} or constants.theme.polarity) == constants.theme.polarity) declaredStaticThemes;
        message = "specializations.ryoku.settings: static theme(s) ${toString declaredStaticThemes} do not match constants.theme.polarity (${constants.theme.polarity}); known polarities: ${builtins.toJSON staticPolarity}";
      }
      {
        assertion = isX86;
        message = "specializations.ryoku: Ryoku is x86_64-linux only (the upstream flake only exposes x86_64-linux packages)";
      }
    ];

    specialisation.ryoku.configuration = { config, pkgs, ... }:
      let
        dm = config.services.displayManager;
        sessions = lib.filter (p: !(lib.elem "ryoku-mango" p.providedSessions)) dm.sessionPackages;
        sessionNames = lib.concatMap (p: p.providedSessions) sessions;
        desktops = pkgs.runCommand "desktops" { preferLocalBuild = true; allowSubstitutes = false; } ''
          mkdir -p "$out/share/"{xsessions,wayland-sessions}
          ${lib.concatMapStrings (pkg: ''
            for d in xsessions wayland-sessions; do
              if test -d ${pkg}/share/$d; then
                ${pkgs.buildPackages.lndir}/bin/lndir ${pkg}/share/$d $out/share/$d
              fi
            done
          '') sessions}
        '';
        user = config.myconfig.constants.user;
        home = config.users.users.${user}.home;
        group = config.users.users.${user}.group;
      in
      {
        system.nixos.tags = [ "ryoku" ];

        imports = [ desktopsOff ];

        myconfig.constants = {
          user = lib.mkForce ryokuUser;
          shell = lib.mkForce "fish";
          theme.catppuccin = lib.mkForce false;
        };

        myconfig.stylix.targets =
          lib.genAttrs stylixLiteOn (_: { enable = lib.mkForce true; })
          // lib.genAttrs stylixLiteOff (_: { enable = lib.mkForce false; });

        stylix.autoEnable = lib.mkForce false;

        programs.dconf.enable = true;
        services.fwupd.enable = true;

        programs.ryoku = {
          # deliberate gate: enabling on aarch64 throws
          enable = isX86;
          defaultCompositor = "hyprland";
          shell = "fish";
          updateFlake = "/var/empty";
        };

        users.users.${user} = {
          isNormalUser = true;
          uid = lib.mkForce ryokuUid;
          subUidRanges = lib.mkForce [{ startUid = ryokuSubId; count = 65536; }];
          subGidRanges = lib.mkForce [{ startGid = ryokuSubId; count = 65536; }];
          extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
        };

        xdg.portal.config = lib.mkForce portalConfig;

        services.displayManager.sessionData = lib.mkForce {
          inherit desktops sessionNames;
          autologinSession =
            if dm.defaultSession != null then dm.defaultSession
            else if sessionNames != [ ] then lib.head sessionNames
            else null;
        };

        environment.systemPackages = lib.optional (cfg.sddmCursorPackage != null) cfg.sddmCursorPackage;

        services.displayManager.sddm.wayland.compositorCommand = lib.mkIf (cfg.sddmCursorTheme != null && dm.sddm.wayland.compositor == "weston") (
          let
            xcfg = config.services.xserver;
            westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
              libinput = {
                enable-tap = config.services.libinput.mouse.tapping;
                left-handed = config.services.libinput.mouse.leftHanded;
              };
              keyboard = {
                keymap_model = xcfg.xkb.model;
                keymap_layout = xcfg.xkb.layout;
                keymap_variant = xcfg.xkb.variant;
                keymap_options = xcfg.xkb.options;
              };
              shell = {
                cursor-theme = cfg.sddmCursorTheme;
                cursor-size = cfg.sddmCursorSize;
              };
            };
          in
          lib.mkForce (lib.concatStringsSep " " [
            "${pkgs.coreutils}/bin/env"
            "XCURSOR_PATH=/run/current-system/sw/share/icons"
            "XCURSOR_THEME=${cfg.sddmCursorTheme}"
            "XCURSOR_SIZE=${toString cfg.sddmCursorSize}"
            "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}"
          ])
        );

        services.displayManager.sddm.settings = lib.mkIf (cfg.sddmCursorTheme != null) {
          Theme = {
            CursorTheme = cfg.sddmCursorTheme;
            CursorSize = cfg.sddmCursorSize;
          };
          General.GreeterEnvironment = lib.concatStringsSep "," (
            lib.optional (config.services.displayManager.sddm.wayland.compositor == "kwin")
              "QT_WAYLAND_SHELL_INTEGRATION=layer-shell"
            ++ [ "XCURSOR_PATH=/run/current-system/sw/share/icons" ]
          );
        };

        environment.persistence = lib.mkIf config.myconfig.services.impermanence.enable {
          "/persist".directories = [
            { directory = "/var/lib/ryoku"; user = "root"; group = "root"; mode = "0755"; }
          ];
        };

        systemd = {
          tmpfiles.rules = [
            "d ${home} ${config.users.users.${user}.homeMode} ${user} ${group} -"
          ];

          user.services = {
            kbd-backlight-relight.enable = lib.mkForce false;
            niri-flake-polkit.enable = lib.mkForce false;
            ryoku-fastfetch-emblem-seed = lib.mkIf (cfg.fastfetchEmblem != null) {
              description = "Seed the declared Ryoku fastfetch emblem through the Hub import";
              wantedBy = [ "ryoku-session.target" ];
              partOf = [ "ryoku-session.target" ];
              requires = [ "ryoku-materialize.service" ];
              after = [ "ryoku-materialize.service" ];
              before = [ "ryoku-shell.service" ];
              unitConfig.ConditionUser = user;
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = fastfetchEmblemScript;
              };
            };
            ryoku-settings-seed = lib.mkIf hasSettings {
              description = "Seed declared Ryoku settings into the user's JSON stores";
              wantedBy = [ "ryoku-session.target" ];
              partOf = [ "ryoku-session.target" ];
              requires = [ "ryoku-materialize.service" ];
              after = [ "ryoku-materialize.service" ];
              before = [ "ryoku-shell.service" ];
              unitConfig.ConditionUser = user;
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = settingsSeedScript;
              };
            };
          };

          services.ryoku-sddm-theme-seed =
            lib.mkIf (config.myconfig.services.impermanence.enable && config.services.displayManager.sddm.enable)
              (
                let s = config.system.activationScripts.ryokuSddmTheme;
                in
                {
                  wantedBy = [ "display-manager.service" ];
                  before = [ "display-manager.service" ];
                  unitConfig.RequiresMountsFor = [ "/var/lib/ryoku" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };
                  script = if builtins.isString s then s else s.text;
                }
              );
        };

        environment.sessionVariables = lib.mkIf config.home-manager.users.${user}.programs.yazi.enable {
          YAZI_CONFIG_HOME = "${home}/.config/yazi-user";
        };

        home-manager.users.${user} =
          { config, lib, ... }:
          let
            cf = config.xdg.configFile;
            fishUser = pkgs.runCommand "ryoku-user.fish" { } ''
              ${pkgs.gnused}/bin/sed '/^set -q __fish_home_manager_config_sourced; and exit$/d' ${cf."fish/config.fish".source} > $out
            '';
          in
          {
            config = lib.mkMerge [
              { stylix.autoEnable = lib.mkForce false; }
              (lib.mkIf (baseCatppuccin && config.programs.eza.enable) {
                catppuccin.eza.enable = lib.mkForce true;
              })
              (lib.mkIf config.programs.kitty.enable {
                xdg.configFile."kitty/kitty.conf".enable = lib.mkForce false;
                xdg.configFile."kitty/user.conf".source = cf."kitty/kitty.conf".source;
              })
              (lib.mkIf config.programs.fish.enable {
                xdg.configFile."fish/config.fish".enable = lib.mkForce false;
                xdg.configFile."fish/user.fish".source = fishUser;
              })
              (lib.mkIf config.programs.yazi.enable {
                xdg.configFile."yazi/yazi.toml".enable = lib.mkForce false;
                xdg.configFile."yazi-user".source = yaziUserConfig cf;
                home.sessionVariables.YAZI_CONFIG_HOME = "${config.home.homeDirectory}/.config/yazi-user";
              })
            ];
          };
      };
  };
}
