{ delib
, inputs
, ...
}:
delib.host {
  name = "nixos-laptop";

  home = {
    home.activation.createLaptopDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    '';
  };
}
