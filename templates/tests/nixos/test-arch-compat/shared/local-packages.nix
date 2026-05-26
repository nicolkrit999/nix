{ delib
, ...
}:
delib.module {
  name = "arch-compat.local-packages";

  home.always = { ... }: {
    home.packages = [ ];
  };
}
