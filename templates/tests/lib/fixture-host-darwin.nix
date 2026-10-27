# Minimal nix-darwin fixture host (not a real host, not in the flake outputs).
#
# Usage:  fx = import ../../lib/fixture-host-darwin.nix flake;
#   fx.mkDarwin { paths = [ <abs path of module under test> ]; modules = [ <module> ]; }
#       -> evaluated darwin system (use `.config`, `.extendModules { modules = [ ... ]; }`).
#          paths   : extra denix files loaded on top of the base set (default [ ]).
#          modules : extra modules applied via extendModules (default [ ]).
#   fx.src         -> flake source root as a path (build `fx.src + "/modules/..."` paths).
#   fx.hmOf cfg    -> home-manager config of the fixture user (cfg = a `.config`).
# Base set: constants schema, catppuccin theme, darwin always-on toplevel files and the
# `minimal-darwin` host (user krit, aarch64-darwin) from test-minimal-defaults/shared.
# Every module under test is OFF unless the caller enables it.
flake:
let
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;

  basePaths = [
    (src + "/templates/tests/darwin/test-minimal-defaults/shared/host-minimal-darwin.nix")
    (src + "/modules/darwin/config/constants-darwin.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/common/themes/catppuccin.nix")
    (src + "/modules/darwin/toplevel/common-configuration-darwin.nix")
    (src + "/modules/darwin/toplevel/home-darwin.nix")
    (src + "/modules/darwin/toplevel/user-darwin.nix")
    (src + "/modules/darwin/toplevel/nix-darwin.nix")
  ];
in
{
  inherit src;

  mkDarwin = { paths ? [ ], modules ? [ ] }:
    let
      configs = flake.inputs.denix.lib.configurations {
        moduleSystem = "darwin";
        homeManagerUser = "krit";
        extensions = with flake.inputs.denix.lib.extensions; [
          args
          (base.withConfig {
            args.enable = true;
            rices.enable = false;
          })
        ];
        specialArgs = {
          inherit (flake) inputs;
          moduleSystem = "darwin";
        };
        paths = basePaths ++ paths;
        exclude = [ ];
      };
    in
    configs.minimal-darwin.extendModules { inherit modules; };

  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
}
