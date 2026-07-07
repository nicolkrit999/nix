{ delib, pkgs, moduleSystem, ... }:
let
  # Shared home-manager `programs.ssh.settings` matchBlocks - used by both the
  # NixOS path (nested under home-manager.users.<user>) and the standalone
  # home-manager path below, so they can't drift apart.
  mkSshSettings = user: {
    "nicol-nas 192.168.1.98 ssh.nicolkrit.ch" = {
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
      ProxyCommand = "cloudflared access ssh --hostname %h";
    };
  };
in
delib.module {
  name = "krit.system.ssh-config";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    systemd.tmpfiles.rules = [
      "d /home/${myconfig.constants.user}/.ssh 0700 ${myconfig.constants.user} users -"
    ];

    environment.systemPackages = [ pkgs.cloudflared ];
    programs.ssh.knownHosts = {
      "gitea-ssh.nicolkrit.ch" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";
      };
    };
    programs.ssh.extraConfig = ''
      Host nicol-nas 192.168.1.98 ssh.nicolkrit.ch
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
        IdentitiesOnly yes
        User krit

      Host github.com
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_github

      Host gitea-ssh.nicolkrit.ch
        IdentityFile /home/${myconfig.constants.user}/.ssh/id_github
        IdentitiesOnly yes
        ProxyCommand cloudflared access ssh --hostname %h
    '';

    # Manage ~/.ssh/config via home-manager so switching away from the school
    # specialization (which also sets programs.ssh) properly rewrites the file.
    # Without this, the school spec's ~/.ssh/config symlink persists in the
    # default profile because home-manager only cleans up files it previously
    # owned in the same activation chain.
    home-manager.users.${myconfig.constants.user} = { ... }: {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = mkSshSettings myconfig.constants.user;
      };
    };
  };

  # Standalone home-manager builds (e.g. Nicol-NAS) have no NixOS system layer
  # to hold `programs.ssh.knownHosts` / the system-wide `programs.ssh.extraConfig`
  # / `environment.systemPackages` / tmpfiles rule - those are all NixOS-only
  # options. Only the pieces with a home-manager equivalent are ported:
  #   - cloudflared via home.packages (needed for the gitea ProxyCommand)
  #   - the pinned gitea host key via ~/.ssh/known_hosts (home-manager's own
  #     programs.ssh has no `knownHosts` option, unlike the NixOS module)
  #   - the same ~/.ssh/config matchBlocks as the NixOS path
  # The tmpfiles rule that pre-creates ~/.ssh 0700 is skipped: home-manager's
  # own activation creates parent dirs for the files it manages.
  #
  # Guarded via a plain `if moduleSystem == "home"`, NOT `lib.mkIf` - see the
  # matching comment in git-ssh-signing.nix / feedback_delib_home_ifenable_patterns
  # memory for why `lib.mkIf` is unsafe here (structurally-present option
  # paths on NixOS/Darwin builds where they'd never be declared).
  home.ifEnabled =
    { myconfig, ... }:
    if moduleSystem == "home" then
      let
        user = myconfig.constants.user;
      in
      {
        home.packages = [ pkgs.cloudflared ];

        # Pinned host keys (gitea + GitHub's official keys, see
        # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
        # This file is a home-manager-managed store symlink and therefore
        # read-only at runtime - ssh can never append newly-trusted hosts to
        # it (TOFU). UserKnownHostsFile below points ssh at this pinned file
        # *and* a second, writable `known_hosts.local` so ad-hoc hosts (e.g.
        # `ssh -T git@github.com` before this pin existed, or any other new
        # host) can actually be persisted instead of re-prompting forever.
        home.file.".ssh/known_hosts".text = ''
          gitea-ssh.nicolkrit.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC
          github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
          github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
          github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
        '';

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = mkSshSettings user // {
            "*" = {
              # Managed (read-only) known_hosts first, then a writable
              # sibling file so ssh's TOFU prompt for brand-new hosts can
              # actually append somewhere instead of failing every time.
              UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts.local";
            };
          };
        };
      }
    else
      { };
}
