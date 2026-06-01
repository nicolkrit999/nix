{ delib
, lib
, config
, ...
}:
delib.module {
  name = "specializations.deep-focus";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;
    specialisation.deep-focus.configuration =
      let
        c = config.myconfig.constants;
        term = c.terminal.name;
        smartLaunch =
          app: if builtins.elem app c.terminalApps then "${term} --class ${app} -e ${app}" else app;
      in
      {
        system.nixos.tags = [ "deep-focus" ];

        # Force swaync so DND mode works regardless of host config
        myconfig.services.swaync.enable = lib.mkForce true;

        myconfig.programs.hyprland.execOnce = lib.mkForce [
          "[workspace 1 silent] ${c.browser}"
          "[workspace 2 silent] ${smartLaunch c.editor}"
          "[workspace 3 silent] ${smartLaunch c.fileManager}"
          "[workspace 4 silent] ${term}"
          "swaync-client -d -b"
        ];

        myconfig.programs.hyprland.windowRules = lib.mkAfter [
          { match.class = "^(${c.browser})$"; workspace = "1"; }
          { match.class = "^(${c.editor})$"; workspace = "2"; }
          { match.class = "^(${c.fileManager})$"; workspace = "3"; }
          { match.class = "^(${term})$"; workspace = "4"; }
        ];

        myconfig.programs.niri.execOnce = lib.mkForce [
          "${c.browser}"
          "sh -c 'sleep 2 && ${smartLaunch c.editor}'"
          "sh -c 'sleep 4 && ${smartLaunch c.fileManager}'"
          "sh -c 'sleep 6 && ${term}'"
          "sh -c 'sleep 8 && swaync-client -d -b'"
        ];
      };
  };
}
