{ ... }:
# Importing modules.nix is not necessary since flake.nix already handle it automatically
{
  imports = [
    ./pwa.nix
    ./home.nix
    #./wrappers.nix 
  ];
}
