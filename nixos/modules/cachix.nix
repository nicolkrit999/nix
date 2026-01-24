{
  config,
  pkgs,
  lib,
  vars,
  ...
}:

let
  cfg = vars.cachix;
  # Dynamically find the sops file based on hostname
  sopsFile = ../../hosts/${vars.hostname}/optional/host-sops-nix/${vars.hostname}-secrets-sops.yaml;
in
{
  # 1. Enable Cachix (Pulling) - For ALL enabled hosts
  config =
    lib.mkIf (cfg.enable) {

      # Configure Nix to use your cache
      nix.settings = {
        substituters = [ "https://${cfg.name}.cachix.org" ];
        trusted-public-keys = [ cfg.publicKey ];
      };

      # CLI tool
      environment.systemPackages = [ pkgs.cachix ];

      # 2. Enable Pushing (only for the builder)
    }
    // lib.mkIf (cfg.enable && cfg.push) {

      # Define the secret for the auth token
      sops.secrets."cachix-auth-token" = {
        sopsFile = sopsFile;
        mode = "0440";
        owner = vars.user;
        group = "wheel";
      };

      # Create a wrapper alias to rebuild AND push in one command
      # Usage: just type "rebuild-push" in your terminal
      environment.shellAliases = {
        rebuild-push = "export CACHIX_AUTH_TOKEN=$(cat ${
          config.sops.secrets."cachix-auth-token".path
        }) && sudo nixos-rebuild switch --flake . && nix path-info -r /run/current-system | cachix push ${cfg.name}";
      };

      environment.systemPackages = [ pkgs.cachix ];
    };
}
