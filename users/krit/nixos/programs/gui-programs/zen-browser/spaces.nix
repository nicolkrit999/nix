{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
# Containers and spaces write to zen-sessions.jsonlz4, which Zen mmap-locks.
# The activation script pgreps for "zen" and fails the build if it's running.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      # ── Containers (cookie isolation, like separate browser profiles) ───────
      # Icons must be predefined Firefox strings, not emoji.
      # Valid icons: fingerprint briefcase dollar cart circle gift vacation
      #              food fruit pet tree chill fence
      # Valid colors: blue turquoise green yellow orange red pink purple
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

      # ── Spaces (visual tab workspaces within Zen, independent of containers)
      # Emoji icons ARE supported here.
      spacesForce = true;
      spaces = {
        "Entertainment & Social" = {
          id = "10000000-0000-4000-8000-000000000001";
          position = 1000;
          icon = "📺️";
        };
        "Personal finance" = {
          id = "10000000-0000-4000-8000-000000000002";
          position = 2000;
          icon = "🏦";
        };
        "Self-hosting" = {
          id = "10000000-0000-4000-8000-000000000003";
          position = 3000;
          icon = "💿️";
        };
        "Various" = {
          id = "10000000-0000-4000-8000-000000000004";
          position = 4000;
          icon = "❓️";
        };
      };
    };
  };
}
