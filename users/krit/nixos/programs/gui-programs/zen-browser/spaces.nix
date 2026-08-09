{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      # ── Containers (cookie isolation, like separate browser profiles) ───────
      # Icons must be predefined Firefox strings, not emoji.
      containersForce = true;
      containers = {
        "General" = {
          id = 1;
          color = "green";
          icon = "circle";
        };
        "Secondary" = {
          id = 2;
          color = "purple";
          icon = "fingerprint";
        };
        "Work" = {
          id = 3;
          color = "blue";
          icon = "briefcase";
        };
        "University" = {
          id = 4;
          color = "turquoise";
          icon = "tree";
        };
      };

      spacesForce = true;
      spaces = {
        "General" = {
          id = "10000000-0000-4000-8000-000000000001";
          position = 1000;
          icon = "🏠️";
          container = 1;
        };
        "Secondary" = {
          id = "10000000-0000-4000-8000-000000000002";
          position = 2000;
          icon = "❔";
          container = 2;
        };
        "Work" = {
          id = "10000000-0000-4000-8000-000000000003";
          position = 3000;
          icon = "💼";
          container = 3;
        };
        "University" = {
          id = "10000000-0000-4000-8000-000000000004";
          position = 4000;
          icon = "📚️";
          container = 4;
        };
      };
    };
  };
}
