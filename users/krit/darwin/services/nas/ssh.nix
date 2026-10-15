{ delib, pkgs, lib, config, ... }:
delib.module {
  name = "krit.services.nas.sshfs";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      user = myconfig.constants.user;
      home = config.users.users.${user}.home;
      nasUser = "root";

      mountPoint = "${nas.mountRoot}/ssh/system_root";

      identityFile = config.sops.secrets.nas_ssh_key.path;
    in
    {
      environment.systemPackages = [ pkgs.sshfs ];
      # sshfs needs macFUSE; installing it opens a one-time system extension approval
      # prompt (System Settings > Privacy & Security) and may need a reboot.
      homebrew.casks = [ "macfuse" ];
      # Tailnet access on darwin comes from the tailscale-app cask (hosts/Krits-MacBook-Pro/local-packages.nix).
      assertions = [
        {
          assertion = myconfig.services.tailscale.darwinCaskPresent || config.services.tailscale.enable;
          message = "krit.services.nas.sshfs reaches the NAS over the tailnet but this darwin host has no Tailscale provider: add the Homebrew cask \"tailscale-app\" or enable myconfig.services.tailscale.";
        }
      ];

      # ---------------------------------------------------------
      # SOPS
      # ---------------------------------------------------------
      sops.secrets.nas_ssh_key = {
        sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
        owner = user;
        mode = "0600";
      };

      # nix-darwin only splices a fixed list of activation script names (preActivation,
      # extraActivation, postActivation, ...) into the activate script; a custom
      # `system.activationScripts.<name>` entry is silently never run. Everything that
      # must happen at activation therefore goes into postActivation.text with mkAfter.
      # Non-recursive on purpose: the directories may hold live network mounts.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        mkdir -p ${lib.escapeShellArg mountPoint}
        chown ${user} ${lib.escapeShellArg nas.mountRoot} ${lib.escapeShellArg "${nas.mountRoot}/ssh"} ${lib.escapeShellArg mountPoint}
      '';

      launchd.user.agents.sshfs-nas = {
        serviceConfig = {
          Label = "com.krit.sshfs-nas";
          RunAtLoad = true;
          KeepAlive = true; # Restart if connection drops
          StandardOutPath = "${home}/Library/Logs/sshfs-nas.log";
          StandardErrorPath = "${home}/Library/Logs/sshfs-nas.err";

          # Environment variables for the script
          EnvironmentVariables = {
            PATH = "${
              lib.makeBinPath [
                pkgs.sshfs
                pkgs.coreutils
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };

        script = ''
          mkdir -p "${mountPoint}"

          # Unmount if stale
          umount "${mountPoint}" || true

          # Mount
          # Host key checking is strict: the NAS key is pinned in /etc/ssh/ssh_known_hosts
          # (nas-identity.nix). Verify on a real Mac that the ssh sshfs spawns reads that file.
          # -f: run in foreground (required for launchd KeepAlive)
          # -o reconnect: vital for network mounts
          sshfs ${nasUser}@${nas.tailnetIp}:/ "${mountPoint}" \
            -f \
            -o IdentityFile="${identityFile}" \
            -o reconnect \
            -o ServerAliveInterval=15 \
            -o Compression=yes \
            -o volname="NAS_Root"
        '';
      };
    };
}
