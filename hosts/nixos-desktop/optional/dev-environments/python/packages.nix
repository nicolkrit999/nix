{
  pkgs,
  python ? pkgs.python313,
}:
with pkgs;
[
  python

  python313Packages.black # The uncompromising code formatter
  python313Packages.flake8 # Style guide enforcement
  python313Packages.isort # Sort imports alphabetically
  jetbrains.pycharm-oss # Python IDE
  python313Packages.pip # Package installer for Python
  pyright # Static type checker
  python313Packages.pylint # Source code analyzer
  python313Packages.ruff # Extremely fast Python linter
  python313Packages.setuptools # Library for packaging Python projects
  python313Packages.venvShellHook # Hook to create and manage virtual-environments
]
