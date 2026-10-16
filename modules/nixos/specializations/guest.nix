{ delib
, lib
, config
, options
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
  guestUid = 2000;
  guestUidStr = toString guestUid;
  excludedPersistDirs = [
    "/var/lib/containers"
    "/var/lib/docker"
    "/var/lib/flatpak"
    "/var/lib/snapper"
    "/var/lib/systemd/linger"
    "/var/lib/tailscale"
  ];

  # Disabled only where the krit user modules are loaded on this host.
  kritOff = lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" "krit" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" "krit" ] ++ path) options) [
        [ "programs" "claude-code-wrappers" ]
        [ "services" "cloud" "googleDrive" ]
        [ "services" "cloud" "onedrivePersonal" ]
        [ "services" "cloud" "pcloud" ]
        [ "services" "cloud" "protonDrive" ]
        [ "services" "nas" "desktop-borg-backup" ]
        [ "services" "nas" "laptop-borg-backup" ]
        [ "services" "nas" "opencloud-mount" ]
        [ "services" "nas" "smb" ]
        [ "services" "nas" "sshfs" ]
        [ "services" "desktop" "flatpak" ]
        [ "services" "laptop" "flatpak" ]
        [ "services" "windows-mount" ]
      ]
    )
  );

  moduleOff = lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) [
        [ "programs" "openlogi" ]
        [ "programs" "thunderbird" ]
        [ "services" "autotrash" ]
        [ "services" "snapshots" ]
      ]
    )
  );

  guestWelcomeScript = pkgs.writeShellScriptBin "guest-welcome" ''
    # Wait for panel/notifications stack so the dialog isn't drawn under it.
    sleep 3
    ${pkgs.zenity}/bin/zenity --warning \
      --title="Sessione Ospite" \
      --width=420 \
      --text="<span size='large' weight='bold'>Sessione temporanea</span>\n\nTutti i dati verranno cancellati al riavvio.\nSalvare i file importanti su una chiavetta USB o servizio cloud."
  '';
in
delib.module {
  name = "specializations.guest";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    specialisation.guest.configuration = {
      system.nixos.tags = [ "guest" ];

      imports = [ kritOff moduleOff ];

      services = {
        displayManager = {
          autoLogin = {
            enable = lib.mkForce true;
            user = lib.mkForce "guest";
          };
          defaultSession = lib.mkForce "xfce";
        };
        xserver.desktopManager.xfce = {
          enable = lib.mkForce true;
          enableScreensaver = false;
        };
        avahi.enable = lib.mkForce false;
        openssh.enable = lib.mkForce false;
      };

      myconfig = {
        programs = {
          caelestia.enable = lib.mkForce false;
          claude-code.enable = lib.mkForce false;
          claude-desktop.enable = lib.mkForce false;
          codex.enable = lib.mkForce false;
          cosmic.enable = lib.mkForce false;
          gnome.enable = lib.mkForce false;
          google-antigravity.enable = lib.mkForce false;
          headroom.enable = lib.mkForce false;
          herdr.enable = lib.mkForce false;
          hyprland.enable = lib.mkForce false;
          kde.enable = lib.mkForce false;
          mango.enable = lib.mkForce false;
          niri.enable = lib.mkForce false;
          nix-alien.enable = lib.mkForce false;
          nix-ld.enable = lib.mkForce false;
          noctalia.enable = lib.mkForce false;
        };
        services = {
          coffee.enable = lib.mkForce false;
          hypridle.enable = lib.mkForce false;
          localsend.enable = lib.mkForce false;
          swaync.enable = lib.mkForce false;
          tailscale.enable = lib.mkForce false;
        };
        bluetooth.enable = lib.mkForce false;
        stylix.enable = lib.mkForce false;
        constants = {
          theme.catppuccin = lib.mkForce false;
          docEditor = lib.mkForce "libreoffice";
          sheetEditor = lib.mkForce "libreoffice";
          slideEditor = lib.mkForce "libreoffice";
        };
      };

      programs.nh.clean.enable = lib.mkForce false;
      users.manageLingering = lib.mkForce false;

      virtualisation = {
        docker.enable = lib.mkForce false;
        podman.enable = lib.mkForce false;
      };

      stylix = {
        base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
        image = lib.mkForce (pkgs.writeText "dummy-image.png" "");
      };

      home-manager.users.${myUserName} =
        { lib, ... }:
        {
          options.stylix.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          config.stylix.enable = lib.mkForce false;
        };

      nix.settings.allowed-users = lib.mkForce [ myUserName ];
      sops.secrets.github_fg_pat_token_nix.mode = lib.mkForce "0400";

      environment.persistence."/persist".directories = lib.mkForce (
        map (d: { inherit (d) directory user group mode; }) (
          lib.filter (d: !(lib.elem d.directory excludedPersistDirs)) config.environment.persistence."/persist".directories
        )
      );

      users = {
        users.guest = {
          isNormalUser = true;
          description = "Guest Account";
          uid = guestUid;
          group = "guest";
          extraGroups = [ "audio" "video" ];
          hashedPassword = "$6$Cqklpmh3CX0Cix4Y$OCx6/ud5bn72K.qQ3aSjlYWX6Yqh9XwrQHSR1GnaPRud6W4KcyU9c3eh6Oqn7bjW3O60oEYti894sqVUE1e1O0";
          createHome = true;
        };
        groups.guest.gid = guestUid;
      };

      fileSystems."/home/guest" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "gid=${guestUidStr}"
          "mode=700"
          "noatime"
          "nodev"
          "nosuid"
          "size=25%"
          "uid=${guestUidStr}"
        ];
      };

      systemd = {
        tmpfiles.rules = [
          "d /var/lib/AccountsService/users 0755 root root -"
          "f /var/lib/AccountsService/users/guest 0644 root root - [User]\\nSession=xfce\\n"
          "f /home/.hidden 0644 root root - guest"
        ];
        slices."user-${guestUidStr}".sliceConfig = {
          MemoryMax = "75%";
          CPUWeight = 90;
        };
      };

      environment = {
        systemPackages = [
          pkgs.file-roller
          (pkgs.firefox.override {
            extraPolicies = {
              DisableFirstRunPage = true;
              DisablePocket = true;
              DisableTelemetry = true;
              DontCheckDefaultBrowser = true;
            };
          })
          pkgs.mousepad
          pkgs.xfce4-screenshooter
        ];

        etc."xdg/autostart/guest-welcome.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Guest Welcome
          Exec=${guestWelcomeScript}/bin/guest-welcome
          OnlyShowIn=XFCE;
          X-GNOME-Autostart-enabled=true
          NoDisplay=false
          Terminal=false
        '';
      };
    };
  };
}
