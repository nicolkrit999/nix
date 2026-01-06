{ ... }:
{
  # Do not import caelestia-config.nix here. It is handled by caelestia-main.nix
  imports = [
    ./caelestia-main.nix
    ./caelestia-wallpaper.nix
  ];
}
