{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Pins write to zen-sessions.jsonlz4, which Zen mmap-locks.
# The activation script pgreps for "zen" and fails the build if it's running.
#
# Each pin is bound to BOTH a container (cookie jar) AND a workspace (space
# UUID). The workspace binding hides the pin in other spaces; the container
# binding sets cookie context when the pin opens.
# Workspace UUIDs must match the IDs in spaces.nix.
#
# isEssential = true → pin appears as a small favicon-only button that can't
# be closed via the X button. Requires zen.window-sync.enabled (set in settings.nix).
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      pinsForce = true;
      pins = {
        # ── Folders (isGroup) ───────────────────────────────────────────────
        # Persist even when empty. Scoped to General space; remove `workspace`
        # to make a folder visible in every space.
        "Social & Entertainment" = {
          id = "30000000-0000-4000-8000-000000000001";
          isGroup = true;
          folderIcon = "📺️";
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 200;
        };
        "Personal finance" = {
          id = "30000000-0000-4000-8000-000000000002";
          isGroup = true;
          folderIcon = "🏦";
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 300;
        };
        "Self hosting" = {
          id = "30000000-0000-4000-8000-000000000003";
          isGroup = true;
          folderIcon = "💿️";
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 400;
        };
        "Utilities" = {
          id = "30000000-0000-4000-8000-000000000004";
          isGroup = true;
          folderIcon = "🔧";
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 500;
        };

        # Work space folders
        "Pc building" = {
          id = "30000000-0000-4000-8000-000000000031";
          isGroup = true;
          folderIcon = "🖥️";
          workspace = "10000000-0000-4000-8000-000000000003"; # Work space
          position = 200;
        };
        "IT services" = {
          id = "30000000-0000-4000-8000-000000000032";
          isGroup = true;
          folderIcon = "🛠️";
          workspace = "10000000-0000-4000-8000-000000000003"; # Work space
          position = 300;
        };

        # University space folders
        "University resources" = {
          id = "30000000-0000-4000-8000-000000000041";
          isGroup = true;
          folderIcon = "🎓";
          workspace = "10000000-0000-4000-8000-000000000004"; # University space
          position = 200;
        };
        "Personal resources" = {
          id = "30000000-0000-4000-8000-000000000042";
          isGroup = true;
          folderIcon = "📔";
          workspace = "10000000-0000-4000-8000-000000000004"; # University space
          position = 300;
        };

        # ── Essential pins ──────────────────────────────────────────────────
        "Reddit" = {
          id = "20000000-0000-4000-8000-000000000001";
          url = "https://www.reddit.com/";
          container = 1; # General
          workspace = "10000000-0000-4000-8000-000000000001"; # General space
          position = 100;
          isEssential = true;
        };
        "Swisscom" = {
          id = "20000000-0000-4000-8000-000000000002";
          url = "https://www.swisscom.ch/";
          container = 2; # Secondary
          workspace = "10000000-0000-4000-8000-000000000002"; # Secondary space
          position = 100;
          isEssential = true;
        };
        "PCPartPicker" = {
          id = "20000000-0000-4000-8000-000000000003";
          url = "https://pcpartpicker.com/";
          container = 3; # Work
          workspace = "10000000-0000-4000-8000-000000000003"; # Work space
          position = 100;
          isEssential = true;
        };
        "iCorsi" = {
          id = "20000000-0000-4000-8000-000000000004";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004"; # University space
          position = 100;
          isEssential = true;
        };
      };
    };
  };
}
