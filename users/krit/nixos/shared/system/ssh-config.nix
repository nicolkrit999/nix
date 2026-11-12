{ delib, lib, moduleSystem, ... }:
let
  giteaHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";

  mkPeers = myconfig:
    lib.filter (n: n != myconfig.constants.hostname) (lib.attrNames (lib.filterAttrs
      (_: h: h.nixos != { } && (h.myconfig.krit.system.ssh-config.enable or false) == true)
      myconfig.hosts));

  peerUser = myconfig: p: myconfig.hosts.${p}.myconfig.constants.user;

  mkPeerSettings = myconfig: user: peers:
    lib.genAttrs peers (p: {
      HostName = p;
      IdentityFile = "/home/${user}/.ssh/id_github";
      IdentitiesOnly = "yes";
      User = peerUser myconfig p;
    });

  mkPeerExtra = myconfig: user: peers:
    lib.concatMapStrings
      (p: ''
        Host ${p}
          HostName ${p}
          IdentityFile /home/${user}/.ssh/id_github
          IdentitiesOnly yes
          User ${peerUser myconfig p}

      '')
      peers;

  mkSshSettings = user: {
    "nicol-nas" = {
      HostName = "nicol-nas.tail9b9ae8.ts.net";
      IdentityFile = "/home/${user}/.ssh/id_github";
      IdentitiesOnly = "yes";
      User = "krit";
    };
    "github.com" = {
      IdentityFile = "/home/${user}/.ssh/id_github";
    };
    "gitea-ssh.nicolkrit.ch" = {
      IdentityFile = "/home/${user}/.ssh/id_github";
      IdentitiesOnly = "yes";
      Port = 2222;
    };
  };
in
delib.module {
  name = "krit.system.ssh-config";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      gatewayAlias = boolOption false;
    };

  nixos.ifEnabled = { cfg, myconfig, ... }:
    let
      user = myconfig.constants.user;
      peers = mkPeers myconfig;
      hostType = n: myconfig.hosts.${n}.type;
      builders = lib.filter (n: hostType n == "desktop") peers;
      flakeDir = "~/${myconfig.constants.flakeDir}";
      remoteBuild = verb: "nh os ${verb} ${flakeDir} --hostname ${myconfig.constants.hostname} --build-host ${peerUser myconfig (lib.head builders)}@${lib.head builders}";
      buildAliases = lib.optionalAttrs
        (hostType myconfig.constants.hostname == "laptop" && builders != [ ] && myconfig.nh.enable)
        {
          sw-laptop-with-desktop = remoteBuild "switch";
          build-laptop-with-desktop = remoteBuild "build";
        };
    in
    {
      services.openssh.authorizedKeysFiles = [
        "%h/.ssh/id_github.pub"
      ];

      systemd.tmpfiles.rules = [
        "d /home/${myconfig.constants.user}/.ssh 0700 ${myconfig.constants.user} users -"
      ];

      programs.ssh.knownHosts = {
        "[gitea-ssh.nicolkrit.ch]:2222" = {
          publicKey = giteaHostKey;
        };
      };
      programs.ssh.extraConfig = ''
        Host nicol-nas
          HostName nicol-nas.tail9b9ae8.ts.net
          IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
          IdentitiesOnly yes
          User krit

        Host github.com
          IdentityFile /home/${myconfig.constants.user}/.ssh/id_github

        Host gitea-ssh.nicolkrit.ch
          IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
          IdentitiesOnly yes
          Port 2222
      '' + "\n" + mkPeerExtra myconfig user peers + lib.optionalString cfg.gatewayAlias ''

      # UniFi Cloud Gateway Fiber console shell - convenience alias so
      # `ssh gateway` works without -i. Key is a manually-generated,
      # non-nix-managed ed25519 keypair whose pubkey is already in root's
      # authorized_keys on the gateway (used for Wake-on-LAN tooling).
      # Each host (desktop, laptop) has its own separate id_gateway_wol
      # keypair - same path/filename, different key material per machine.
      Host gateway
        HostName 192.168.1.1
        User root
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_gateway_wol
        IdentitiesOnly yes
    '';

      # Manage ~/.ssh/config via home-manager so leaving the school specialization rewrites the file.
      home-manager.users.${myconfig.constants.user} = _: {
        home.shellAliases =
          lib.listToAttrs (map (p: lib.nameValuePair "ssh-${p}" "ssh ${p}") peers)
          // buildAliases;
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = mkSshSettings myconfig.constants.user
            // mkPeerSettings myconfig myconfig.constants.user peers
            // lib.optionalAttrs cfg.gatewayAlias {
            # UniFi Cloud Gateway Fiber console shell - see matching comment on
            # the system-wide extraConfig block above.
            "gateway" = {
              HostName = "192.168.1.1";
              User = "root";
              IdentityFile = "/home/${myconfig.constants.user}/.ssh/id_gateway_wol";
              IdentitiesOnly = "yes";
            };
          };
        };
      };
    };

  # Standalone home builds have no NixOS layer: only the pinned known_hosts and ssh config are ported; tmpfiles is skipped.
  #
  # Plain `if`, not lib.mkIf: mkIf leaves option paths structurally present on NixOS/Darwin.
  home.ifEnabled =
    { myconfig, ... }:
    if moduleSystem == "home" then
      let
        user = myconfig.constants.user;
      in
      {
        # Pinned keys (gitea + GitHub official); the file is a read-only store symlink, so known_hosts.local takes new hosts.
        home.file.".ssh/known_hosts".text = ''
          [gitea-ssh.nicolkrit.ch]:2222 ${giteaHostKey}
          github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
          github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
          github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
        '';

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = mkSshSettings user // {
            "*" = {
              # Writable sibling so TOFU can append new hosts.
              UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts.local";
            };
          };
        };
      }
    else
      { };
}
