{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Pins write to zen-sessions.jsonlz4, which Zen mmap-locks.
# The activation script pgreps for "zen" and fails the build if it's running.
#
# Pinned tabs are associated with containers (cookie isolation).
# Spaces are independent — pins appear across all spaces.
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
          position = 100;
        };
        "Swisscom" = {
          id = "20000000-0000-4000-8000-000000000002";
          url = "https://www.swisscom.ch/";
          container = 2; # Secondary
          position = 100;
        };
        "PCPartPicker" = {
          id = "20000000-0000-4000-8000-000000000003";
          url = "https://pcpartpicker.com/";
          container = 3; # Work
          position = 100;
        };
        "iCorsi" = {
          id = "20000000-0000-4000-8000-000000000004";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          position = 100;
        };
      };
    };
  };
}
