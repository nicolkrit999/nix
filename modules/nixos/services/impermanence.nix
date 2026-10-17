{ delib, inputs, ... }:
delib.module {
  name = "services.impermanence";
  options = delib.singleEnableOption false;

  nixos.always = _: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];
  };

  nixos.ifEnabled = _: {
    environment.persistence."/persist" = {
      hideMounts = true; # Remove mounts from commands like lsblk as they are not real separate devices, instead they are bind mounts to the same root filesystem

      directories = [
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
        "/etc/ssh"
        "/var/cache/fscache"
        "/var/db/sudo/lectured"
        "/var/lib/NetworkManager"
        "/var/lib/bluetooth"
        "/var/lib/containers"
        "/var/lib/docker"
        "/var/lib/flatpak"
        "/var/lib/nixos"
        "/var/lib/sddm"
        "/var/lib/snapper"
        "/var/lib/systemd/backlight"
        "/var/lib/systemd/rfkill"
        "/var/lib/systemd/timers"
        "/var/lib/systemd/timesync"
        "/var/lib/tailscale"
        "/var/tmp"
      ];

      files = [
        "/etc/machine-id"
      ];
    };
  };
}
