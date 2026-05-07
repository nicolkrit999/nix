{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.mods = [
      "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
      "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
      "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # Superpins
      "cb5efa80-f1e1-43ce-8c0b-fece8462d225" # Container Halo
      "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better Ctrl+Tab panel
    ];
  };
}
