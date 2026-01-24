{ ... }:
{
  # Do not import home-manager because every host manage its own preferences
  imports = [
    # System-wide configurations
    ./system

    # Specific-use-case configurations
    ./use-cases/system-imports.nix
  ];
}
