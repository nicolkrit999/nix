{ delib
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { myconfig, ... }:
    {
      # Enable data control for clipboard tools
      home.sessionVariables = {
        COSMIC_DATA_CONTROL_ENABLED = 1;
        XDG_SCREENSHOTS_DIR = myconfig.constants.screenshots;
      };
    };
}
