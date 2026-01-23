{ ... }:
# Importing modules.nix is not necessary since flake.nix already handle it automatically
{
  imports = [
    # FIXME: apple music svg logo give error
    #./pwa.nix
    ./home.nix
    #./wrappers.nix
  ];
}
