{ delib
, config
, pkgs
, lib
, ...
}:
delib.module {
  name = "krit.services.nas.smb";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      user = myconfig.constants.user;
      home = config.users.users.${user}.home;
      credentialsFile = config.sops.secrets.nas-krit-credentials.path;

      shares = [
        "Amministrazione-NAS"
        "Default-volume-1"
        "Default-volume-2"
        "docker"
        "Famiglia"
        "Krit SD 512"
        "Momentary-volume-1"
        "personal_folder"
      ];

      mountBase = "${nas.mountRoot}/smb";
      localName = builtins.replaceStrings [ " " ] [ "_" ];
      nsmbConf = "${home}/Library/Preferences/nsmb.conf";

      # The password never appears on a command line: the sops credentials file
      # (username=... / password=..., parsed, never sourced) is rendered into the
      # user's nsmb.conf (mode 0600) for the duration of the run, and
      # `mount_smbfs -N` reads it from there. User and share are percent-encoded
      # (jq @uri) because they sit in the //user@host/share URL.
      #
      # UNTESTED ON A REAL MAC (no Mac exists, CI only). Verify when one is available:
      #  - nsmb.conf section naming: the section is `[SERVER:USER]` and must match the
      #    server string of the URL (here the tailnet IP, so no case issue, but check that
      #    a dotted IP is accepted as a section name; if not, switch the mount URL and the
      #    section to a hostname). `man nsmb.conf` lists the section forms.
      #  - `-N` semantics: "do not prompt for a password"; it must pick the password from
      #    nsmb.conf. Check that it does not fall through to a Keychain prompt or Kerberos.
      #  - Keychain interplay: a stale Keychain entry for the same server/user could win
      #    over nsmb.conf; delete it if mounts ask for a password.
      #  - A password starting with `$$1` is read by smbfs as an obfuscated password; a
      #    newline in the password breaks the rendered file. Neither is expected today.
      #  - The script overwrites the whole nsmb.conf and removes it on exit (the kernel
      #    session keeps the credentials; every 600 s run renders it again). Any hand-written
      #    nsmb.conf settings are lost: put them in the printf below instead.
      #  - Mount point ownership: mount_smbfs needs the mount point to be owned by the
      #    mounting user. The directories are created by the postActivation block below
      #    and by `mkdir -p` here; `chown -R` is deliberately never used because it would
      #    walk live network mounts.
      #  - /Volumes cleanup: macOS may delete the empty /Volumes/nicol_nas tree at boot.
      #    The user agent cannot recreate it (/Volumes is root-owned) and logs a mkdir
      #    error. If that happens, replace the activation block with a RunAtLoad root
      #    launchd daemon that does the mkdir + chown.
      #  - macOS asks once for approval of the Local Network permission for sh/mount_smbfs
      #    when reaching a LAN/tailnet address; approve it in System Settings.
      mountScript = ''
        export LC_ALL=C

        creds=${lib.escapeShellArg credentialsFile}
        conf=${lib.escapeShellArg nsmbConf}

        if [ ! -r "$creds" ]; then
          echo "Credentials file not readable: $creds" >&2
          exit 1
        fi

        SMB_USER=""
        SMB_PASS=""
        while IFS='=' read -r key value || [ -n "$key" ]; do
          case "$key" in
            username) SMB_USER=$value ;;
            password) SMB_PASS=$value ;;
          esac
        done < "$creds"

        if [ -z "$SMB_USER" ] || [ -z "$SMB_PASS" ]; then
          echo "Credentials file lacks username= or password=" >&2
          exit 1
        fi

        mkdir -p "$(dirname "$conf")"
        trap 'rm -f "$conf"' EXIT
        (umask 077 && printf '[%s:%s]\npassword=%s\n' ${lib.escapeShellArg nas.tailnetIp} "$SMB_USER" "$SMB_PASS" > "$conf")
        chmod 600 "$conf"

        enc_user=$(printf '%s' "$SMB_USER" | jq -sRr @uri)

        do_mount() {
          share=$1
          mountpoint="${mountBase}/$2"

          mkdir -p "$mountpoint"

          if mount | grep -qF " on $mountpoint ("; then
            return 0
          fi

          echo "Mounting $share..."
          enc_share=$(printf '%s' "$share" | jq -sRr @uri)
          mount_smbfs -N "//$enc_user@${nas.tailnetIp}/$enc_share" "$mountpoint" \
            || echo "Mounting $share failed" >&2
        }

        ${lib.concatMapStringsSep "\n" (s: "do_mount ${lib.escapeShellArg s} ${lib.escapeShellArg (localName s)}") shares}
      '';

    in
    {
      # Tailnet access on darwin comes from the tailscale-app cask (hosts/Krits-MacBook-Pro/local-packages.nix).
      assertions = [
        {
          assertion = myconfig.services.tailscale.darwinCaskPresent || config.services.tailscale.enable;
          message = "krit.services.nas.smb reaches the NAS over the tailnet but this darwin host has no Tailscale provider: add the Homebrew cask \"tailscale-app\" or enable myconfig.services.tailscale.";
        }
      ];

      sops.secrets.nas-krit-credentials = {
        sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
        owner = user;
      };

      # nix-darwin only splices a fixed list of activation script names (preActivation,
      # extraActivation, postActivation, ...) into the activate script; a custom
      # `system.activationScripts.<name>` entry is silently never run. Everything that
      # must happen at activation therefore goes into postActivation.text with mkAfter.
      # Non-recursive on purpose: the directories may hold live network mounts.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        mkdir -p ${lib.escapeShellArg mountBase}
        chown ${user} ${lib.escapeShellArg nas.mountRoot} ${lib.escapeShellArg mountBase}
      '';

      launchd.user.agents.smb-nas = {
        serviceConfig = {
          Label = "com.krit.smb-nas";
          RunAtLoad = true;
          StandardOutPath = "${home}/Library/Logs/smb-nas.log";
          StandardErrorPath = "${home}/Library/Logs/smb-nas.err";

          StartInterval = 600;

          EnvironmentVariables = {
            PATH = "${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.jq
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };

        script = mountScript;
      };
    };
}
