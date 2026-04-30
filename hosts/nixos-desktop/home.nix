{ delib
, inputs
, ...
}:
delib.host {
  name = "nixos-desktop";

  home = {
    home.activation.createDesktopDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    '';

    programs.fish.interactiveShellInit = ''
      if test -r /run/secrets/hevy_api_key
        set -gx HEVY_API_KEY (cat /run/secrets/hevy_api_key)
      end
    '';
  };
}
