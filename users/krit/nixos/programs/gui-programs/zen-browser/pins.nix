{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Pins write to zen-sessions.jsonlz4, which Zen mmap-locks.
# The activation script pgreps for "zen" and fails the build if it's running.
#
# Each pin is bound to BOTH a container (cookie jar) AND a workspace (space
# UUID). The workspace binding hides the pin in other spaces; the container
# binding sets cookie context when the pin opens.
# Workspace UUIDs must match the IDs in spaces.nix.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      pinsForce = true;
      pins = {
        "Reddit" = {
          id = "20000000-0000-4000-8000-000000000001";
          url = "https://www.reddit.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 100;
        };
        "Swisscom" = {
          id = "20000000-0000-4000-8000-000000000002";
          url = "https://www.swisscom.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002"; # Secondary space
          position = 100;
        };
        "PCPartPicker" = {
          id = "20000000-0000-4000-8000-000000000003";
          url = "https://pcpartpicker.com/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003"; # Work space
          position = 100;
        };
        "iCorsi" = {
          id = "20000000-0000-4000-8000-000000000004";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004"; # University space
          position = 100;
        };
      };
    };
  };
}
