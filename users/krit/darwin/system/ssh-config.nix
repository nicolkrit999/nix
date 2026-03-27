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
        matchBlocks = {
          "github.com" = {
            identityFile = "${sshDir}/id_github";
          };
          "nicol-nas 192.168.1.98 ssh.nicolkrit.ch" = {
            identityFile = "${sshDir}/id_github";
            identitiesOnly = true;
            user = user;
          };
          "gitea-ssh.nicolkrit.ch" = {
            identityFile = "${sshDir}/id_github";
            identitiesOnly = true;
            extraOptions = {
              ProxyCommand = "cloudflared access ssh --hostname %h";
            };
          };
          "gitlab-edu.supsi.ch" = {
            hostname = "gitlab-edu.supsi.ch";
            identityFile = "${sshDir}/id_school";
            identitiesOnly = true;
          };
          "github-school" = {
            hostname = "github.com";
            identityFile = "${sshDir}/id_school";
            identitiesOnly = true;
          };
        };
      };
    };
}
