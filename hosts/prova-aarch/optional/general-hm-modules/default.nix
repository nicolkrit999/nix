{ ... }:
# Importing modules.nix is not necessary since flake.nix already handle it automatically
{
  imports = [
    # FIX: Commented because google-chrome based pwa are not working on aarch64
    #./pwa.nix
    ./home.nix
    #./wrappers.nix
  ];
}
