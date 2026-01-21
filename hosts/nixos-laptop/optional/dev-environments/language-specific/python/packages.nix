{
  pkgs,
  python ? pkgs.python313,
}:
let
  pp = python.pkgs;
in
with python.pkgs;
[
  python

  # 2. LIBRARIES (dynamic)
  pp.black
  pp.flake8
  pp.isort
  pp.pylint
  pp.ruff

  # 3. TOOLS (static)
  pkgs.pyright
  pkgs.jetbrains.pycharm-oss

  # Neovim plugins
  pkgs.vimPlugins.coc-pyright # Python support for CoC

  (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [ p.python ]))

]
