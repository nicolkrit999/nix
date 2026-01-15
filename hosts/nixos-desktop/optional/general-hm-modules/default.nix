{ ... }:
# Importing modules.nix is not necessary since flake.nix already handle it automatically
{
  imports = [ ./web-apps.nix ./home.nix ];
}
