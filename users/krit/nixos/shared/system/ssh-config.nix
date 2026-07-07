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

        home.file.".ssh/known_hosts".text = ''
          gitea-ssh.nicolkrit.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC
        '';

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = mkSshSettings user;
        };
      }
    else
      { };
}
