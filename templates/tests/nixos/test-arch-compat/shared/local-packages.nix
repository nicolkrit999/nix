{ delib
, pkgs
, ...
}:
delib.module {
  name = "arch-compat.local-packages";

  home.always = { ... }: {
    home.packages = with pkgs; [
      proton-pass # intentionally x86-only — verifies the test catches TRANSITIVE DEP failures without stopping
    ];
  };
}
