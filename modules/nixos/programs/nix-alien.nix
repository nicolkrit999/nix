{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.nix-alien";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    programs.nix-ld.enable = true;

    environment.systemPackages = [
      (inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien.override {
        python3 = pkgs.python3.override {
          packageOverrides = _: pyPrev: {
            deal = pyPrev.deal.overridePythonAttrs (old: {
              disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
                "tests/test_linter/test_extractors/test_exceptions.py"
              ];
            });
          };
        };
      })
    ];
  };
}
