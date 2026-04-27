{ delib, pkgs, ... }:
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
  };
}
