{ delib, config, lib, pkgs, ... }:
delib.module {
  name = "krit.services.nas.opencloud";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      user = myconfig.constants.user;
      home = config.users.users.${user}.home;
      opencloudRoot = "${nas.mountRoot}/webdav/opencloud";

      spaces = [
        {
          name = "personal";
          path = "Personal";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$e644ca2a-2f80-4b31-89f0-6c848de661cc/";
        }
        {
          name = "uni_general";
          path = "University/0001-General";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$f5684f49-3aad-4268-bfc5-e00a26401c9f";
        }
        {
          name = "uni_supsi";
          path = "University/0002-Supsi";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$cce01961-8714-4f83-a44a-0b9af5b06ffa";
        }
        {
          name = "uni_usi";
          path = "University/0003-Usi";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$bbcb3f1c-eb07-4379-b2f6-39bae25f1f31";
        }
      ];

      mkOpencloudAgent = space:
        let
          remoteName = "nas_opencloud_${space.name}";
          remoteEnvPrefix = "RCLONE_CONFIG_${lib.toUpper remoteName}";
          mountPoint = "${opencloudRoot}/${space.path}";
        in
        {
          name = "opencloud-rclone-${space.name}";
          value = {
            serviceConfig = {
              Label = "com.krit.opencloud-rclone-${space.name}";
              RunAtLoad = true;
              KeepAlive = true;
              StandardOutPath = "${home}/Library/Logs/rclone-opencloud-${space.name}.log";
              StandardErrorPath = "${home}/Library/Logs/rclone-opencloud-${space.name}.err";
              EnvironmentVariables = {
                PATH = "${
                  lib.makeBinPath [
                    pkgs.rclone
                    pkgs.coreutils
                  ]
                }:/usr/bin:/bin:/usr/sbin:/sbin";
              };
            };

            script = ''
              OC_USER=$(cat ${config.sops.secrets.nas_opencloud_user.path})
              OC_PASS=$(cat ${config.sops.secrets.nas_opencloud_pass.path})

              # rclone only accepts an obscured password; "obscure -" reads it from stdin
              # so the plaintext never lands on rclone's argv.
              OC_PASS_OBSCURED=$(printf '%s' "$OC_PASS" | rclone obscure -)

              export ${remoteEnvPrefix}_TYPE=webdav
              export ${remoteEnvPrefix}_URL=${lib.escapeShellArg space.url}
              # OpenCloud descends from ownCloud Infinite Scale and rclone has no "opencloud"
              # vendor; vendor=owncloud is kept. rclone also has a dedicated "infinitescale"
              # vendor that may fit better; switching it is untested (no Mac, module disabled).
              # On a real Mac, try VENDOR=infinitescale and compare directory listings and
              # write/rename behaviour before adopting it.
              export ${remoteEnvPrefix}_VENDOR=owncloud
              export ${remoteEnvPrefix}_USER="$OC_USER"
              export ${remoteEnvPrefix}_PASS="$OC_PASS_OBSCURED"

              mkdir -p "${mountPoint}"
              umount "${mountPoint}" || true

              # --vfs-cache-mode writes: Essential for stability
              rclone mount ${remoteName}: "${mountPoint}" \
                --vfs-cache-mode writes \
                --volname "OpenCloud ${space.name}"
            '';
          };
        };

      spaceMountDirs = map (space: "${opencloudRoot}/${space.path}") spaces;
      chownDirs = lib.unique (
        [ nas.mountRoot "${nas.mountRoot}/webdav" opencloudRoot ]
        ++ map dirOf spaceMountDirs
        ++ spaceMountDirs
      );
    in
    {
      environment.systemPackages = [ pkgs.rclone ];
      # rclone mount needs macFUSE; installing it opens a one-time system extension approval
      # prompt (System Settings > Privacy & Security) and may need a reboot.
      homebrew.casks = [ "macfuse" ];
      # Tailnet access on darwin comes from the tailscale-app cask (hosts/Krits-MacBook-Pro/local-packages.nix).
      assertions = [
        {
          assertion = myconfig.services.tailscale.darwinCaskPresent || config.services.tailscale.enable;
          message = "krit.services.nas.opencloud reaches the NAS over the tailnet but this darwin host has no Tailscale provider: add the Homebrew cask \"tailscale-app\" or enable myconfig.services.tailscale.";
        }
      ];

      # Shared account across all spaces.
      sops.secrets = {
        nas_opencloud_user = {
          sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
          owner = user;
        };
        nas_opencloud_pass = {
          sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
          owner = user;
        };
      };

      # nix-darwin only splices a fixed list of activation script names (preActivation,
      # extraActivation, postActivation, ...) into the activate script; a custom
      # `system.activationScripts.<name>` entry is silently never run. Everything that
      # must happen at activation therefore goes into postActivation.text with mkAfter.
      # Non-recursive on purpose: the directories may hold live network mounts.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        ${lib.concatMapStringsSep "\n" (dir: "mkdir -p ${lib.escapeShellArg dir}") spaceMountDirs}
        chown ${user} ${lib.concatMapStringsSep " " lib.escapeShellArg chownDirs}
      '';

      launchd.user.agents = lib.listToAttrs (map mkOpencloudAgent spaces);
    };
}
