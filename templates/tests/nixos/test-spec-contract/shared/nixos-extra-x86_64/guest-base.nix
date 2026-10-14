{ inputs, ... }:
{
  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.nix-sops.nixosModules.sops
  ];

  environment.persistence."/persist".directories = [
    "/etc/ssh"
    "/var/lib/systemd/linger"
  ];
  sops.secrets.github_fg_pat_token_nix.mode = "0444";

  services.openssh.enable = true;
  services.avahi.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;
  nix.settings.allowed-users = [ "@wheel" ];
}
