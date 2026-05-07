# Zen Browser Declarative Setup — TODO

## Phase 1 — DONE ✅
Build + live testing both passed.

- [x] Global module: DisableTelemetry, DontCheckDefaultBrowser, setAsDefaultBrowser=false, keyboardShortcutsVersion
- [x] settings.nix: DisableAppUpdate, DisablePocket, zen prefs, window-sync, autoDisableScopes=0
- [x] mods.nix: No Top Sites mod
- [x] search.nix: Kagi as default (custom engine, force=true)
- [x] extensions.nix: full rycee list (ublock-origin, proton-pass, firefox-color, sponsorblock, gesturefy, privacy-badger, screenshot-capture-annotate, behind-the-overlay-revival, onetab, simplelogin, kagi-search, youtube-screenshot-button); buildFirefoxXpiAddon for unfree support
- [x] spaces.nix: 4 containers + 4 spaces 1:1 mapped (General 🏠️ / Secondary ❔ / Work 💼 / University 📚️), each space pinned to its container
- [x] pins.nix: 4 essential pins, each bound to its container + space (Reddit / Swisscom / PCPartPicker / iCorsi)
- [x] keyboard.nix: empty host-specific block ready to fill
- [x] hosts/nixos-laptop/default.nix: myBrowser = "zen-beta"
- [x] Fixed stylix profile-name bug (was "krit", now "default")
- [x] Cleaned stale ~/.config/zen/krit/ and Profile Groups/ on disk
- [x] Tested: default browser, containers, spaces, essential pins, Kagi search, extensions, prefs, policies all working

## Phase 1 — Outstanding
- [x] ~~Ctrl+Alt+C (zen-compact-mode-toggle) not firing.~~ Diagnosed: `keyboardVariant = "intl"` makes Ctrl+Alt act as AltGr, swallowing the chord. Rebound to **Ctrl+Shift+M** — but that collides with Firefox Responsive Design Mode. Final binding: **Alt+Shift+M** in `modules/common/programs/zen-browser.nix`. Pending live-test confirmation after rebuild.

## Phase 2 — Not started
- [ ] Add more pinned tabs per container (many more expected)
- [ ] Add host-specific keyboard shortcuts inside keyboard.nix
- [ ] Add normal (policy-based) extensions to extensions.nix when needed
- [ ] Add userchrome.nix when CSS customizations are wanted
- [ ] Add declarative `browser.uiCustomization.state` once user has manually pinned extensions to toolbar (paste from about:config)
- [ ] DRY: factor `buildFirefoxXpiAddon` out of librewolf-common.nix and zen-browser/extensions.nix into a shared helper
- [ ] Review spacesForce / pinsForce / containersForce (all true — wipes undeclared items)

## Known Limitations / Design Decisions
- Container icons CANNOT be emoji in Firefox/Zen — used predefined strings (circle, fingerprint, briefcase, tree)
- Emoji icons appear on Spaces only
- Spaces 1:1 with containers — switching space changes both pinned-tab visibility AND default cookie context for new tabs
- pinsForce / spacesForce / containersForce all true → close Zen before every rebuild
- Essential pins (isEssential=true) require `zen.window-sync.enabled` (set in settings.nix)
- search.force = true: only Kagi available (built-ins removed)
- keyboardShortcutsVersion = 17: bump in global module if Zen updates
- onetab is unfree → uses pkgs.callPackage path so system allowUnfree applies
