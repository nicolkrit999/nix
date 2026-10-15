{ delib, config, moduleSystem, ... }:
delib.module {
  name = "krit.services.nas";

  options = with delib; moduleOptions {
    tailnetIp = strOption "100.101.189.91";
    host = strOption "nicol-nas.tail9b9ae8.ts.net";
    mountRoot = strOption (if moduleSystem == "darwin" then "/Volumes/nicol_nas" else "/mnt/nicol_nas");
    hostKey = strOption "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSXm5dIDPoAmWwxl4LBlTOHCfxdt2lGFF2AGYCkjy3c";
  };

  nixos.always =
    let
      nas = config.myconfig.krit.services.nas;
    in
    {
      programs.ssh.knownHosts."nicol-nas-tailnet" = {
        hostNames = [ nas.host nas.tailnetIp ];
        publicKey = nas.hostKey;
      };
    };
}
