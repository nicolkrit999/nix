{ delib, pkgs, ... }:
delib.module {
  name = "krit.system.ssh-config";
  options = delib.singleEnableOption false;

  darwin.ifEnabled = { ... }: {
    environment.systemPackages = [ pkgs.cloudflared ];
    programs.ssh.knownHosts = {
      "gitea-ssh.nicolkrit.ch" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";
      };
    };
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user;
      sshDir = "/Users/${user}/.ssh";
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "github.com" = {
            IdentityFile = "${sshDir}/id_github";
          };
          "nicol-nas 192.168.1.98 ssh.nicolkrit.ch" = {
            IdentityFile = "${sshDir}/id_github";
            IdentitiesOnly = true;
            User = user;
          };
          "gitea-ssh.nicolkrit.ch" = {
            IdentityFile = "${sshDir}/id_github";
            IdentitiesOnly = true;
            ProxyCommand = "cloudflared access ssh --hostname %h";
          };
          "gitlab-edu.supsi.ch" = {
            Hostname = "gitlab-edu.supsi.ch";
            IdentityFile = "${sshDir}/id_school";
            IdentitiesOnly = true;
          };
          "github-school" = {
            Hostname = "github.com";
            IdentityFile = "${sshDir}/id_school";
            IdentitiesOnly = true;
          };
        };
      };
    };
}
