{ delib, inputs, ... }:
delib.module {
  name = "services.impermanence";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];
  };

  nixos.ifEnabled = { ... }: {
    environment.persistence."/persist" = {
      hideMounts = true; # Remove mounts from commands like lsblk as they are not real separate devices, instead they are bind mounts to the same root filesystem

      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/etc/ssh"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/tailscale"
        "/var/lib/systemd/timers"
        "/var/db/sudo/lectured"
        "/var/tmp"
        "/var/lib/sddm"
        "/var/lib/flatpak"
        "/var/lib/docker"
        "/var/lib/containers"
      ];

      files = [
        "/etc/machine-id"
        "/etc/adjtime"
      ];
    };
  };
}
