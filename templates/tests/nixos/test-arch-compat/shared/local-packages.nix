{ delib
, ...
}:
delib.module {
  name = "arch-compat.local-packages";

  home.always = _: {
    home.packages = [ ];
  };
}
