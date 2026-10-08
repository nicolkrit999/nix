{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "programs.cosmic";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =

    {
      services.desktopManager.cosmic.enable = true;

      environment.cosmic.excludePackages = with pkgs; [
        cosmic-term
        cosmic-store
        cosmic-app-library
        cosmic-edit
        cosmic-files
        cosmic-player
      ];

      services.displayManager.cosmic-greeter.enable = false;

      services.desktopManager.cosmic.showExcludedPkgsWarning = false;

      environment.systemPackages = lib.optionals config.stylix.enable (
        let
          tkFont = family: ''
            (
                family: "${family}",
                weight: Normal,
                stretch: Normal,
                style: Normal,
            )
          '';
        in
        [
          (pkgs.linkFarm "cosmic-tk-fonts" [
            {
              name = "share/cosmic/com.system76.CosmicTk/v1/interface_font";
              path = pkgs.writeText "interface_font" (tkFont config.stylix.fonts.sansSerif.name);
            }
            {
              name = "share/cosmic/com.system76.CosmicTk/v1/monospace_font";
              path = pkgs.writeText "monospace_font" (tkFont config.stylix.fonts.monospace.name);
            }
          ])
        ]
      );
    };
}
