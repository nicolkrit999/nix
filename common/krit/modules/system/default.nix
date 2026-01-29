{ ... }:
{
  # ./dev-environments is handled by ".envrc" files in the relevant projects
  # ./nas must be imported in the host "configuration.nix"
  imports = [
    ./gui-programs
    ./utilities
  ];
}
