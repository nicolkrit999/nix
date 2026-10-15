{ delib, config, moduleSystem, ... }:
let
  nas = config.myconfig.krit.services.nas;
  pin = {
    hostNames = [ nas.host nas.tailnetIp ];
    publicKey = nas.hostKey;
  };
in
delib.module {
  name = "krit.services.nas";

  options = with delib; moduleOptions {
    tailnetIp = strOption "100.101.189.91";
    host = strOption "nicol-nas.tail9b9ae8.ts.net";
    mountRoot = strOption (if moduleSystem == "darwin" then "/Volumes/nicol_nas" else "/mnt/nicol_nas");
    # Account on the NAS itself, independent of the local constants.user
    user = strOption "krit";
    hostKey = strOption "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICSXm5dIDPoAmWwxl4LBlTOHCfxdt2lGFF2AGYCkjy3c";
  };

  nixos.always.programs.ssh.knownHosts."nicol-nas-tailnet" = pin;

  # nix-darwin writes the same pin to /etc/ssh/ssh_known_hosts. Verify on a real Mac that the
  # nix-provided ssh (borg's PATH) and /usr/bin/ssh both read that file.
  darwin.always.programs.ssh.knownHosts."nicol-nas-tailnet" = pin;
}
