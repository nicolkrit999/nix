{ delib
, pkgs
, ...
}:
delib.module {
  name = "arch-compat.local-packages";

  home.always = { ... }: {
    home.packages = with pkgs; [
      proton-pass
    ];
  };
}
