{ delib
, inputs
, ...
}:
delib.host {
  name = "nixos-desktop";

  home = {
    home.activation.createDesktopDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    '';
  };
}
