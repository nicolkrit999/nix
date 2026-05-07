# Zen Browser Declarative Setup — TODO

## Phase 1 — Build (DONE) ✅
- [x] Global module: DisableTelemetry, setAsDefaultBrowser=false, zen-compact-mode-toggle shortcut, keyboardShortcutsVersion
- [x] settings.nix: DisableAppUpdate, DisablePocket, zen prefs
- [x] mods.nix: No Top Sites mod
- [x] search.nix: Kagi as default
- [x] extensions.nix: ublock-origin + proton-pass (rycee), placeholder for normal extensions
- [x] spaces.nix: 4 containers (General/Secondary/Work/University) + 4 spaces (Entertainment & Social / Personal finance / Self-hosting / Various)
- [x] pins.nix: one pinned tab per container (Reddit, Swisscom, PCPartPicker, iCorsi)
- [x] keyboard.nix: empty host-specific block ready to fill
- [x] hosts/nixos-laptop/default.nix: changed myBrowser from "helium" to "zen-beta"
- [x] Fixed stylix profile-name bug (was "krit", now "default")
- [x] Cleaned stale ~/.config/zen/krit/ and Profile Groups/ on disk
- [x] Rebuild succeeded

## Phase 1 — Live testing (pending user)
Launch Zen and verify:
- [ ] Default browser: clicking external links opens Zen
- [ ] 4 containers: General / Secondary / Work / University with their Firefox icons
- [ ] 4 spaces in sidebar: Entertainment & Social 📺️ / Personal finance 🏦 / Self-hosting 💿️ / Various ❓️
- [ ] 4 pinned tabs (one per container): Reddit / Swisscom / PCPartPicker / iCorsi
- [ ] Kagi is the search engine
- [ ] Extensions installed: ublock-origin, proton-pass
- [ ] Mod "No Top Sites" active on new-tab page
- [ ] Compact mode + tabbar hidden + urlbar floats (zen prefs)
- [ ] Ctrl+Alt+C toggles compact mode
- [ ] about:policies shows DisableTelemetry / DisableAppUpdate / DisablePocket

## Phase 2 — After user confirms tests pass
- [ ] Add more pinned tabs per container (many more expected)
- [ ] Add host-specific keyboard shortcuts inside keyboard.nix
- [ ] Add normal (policy-based) extensions to extensions.nix when needed
- [ ] Add userchrome.nix when CSS customizations are wanted
- [ ] Review spacesForce / pinsForce / containersForce settings (currently all true — wipes undeclared items)
- [ ] Verify zen-compact-mode-toggle shortcut Ctrl+Alt+C doesn't conflict with system shortcuts on laptop
- [ ] Verify container icon choices (predefined Firefox strings, not emoji) — user may want to adjust

## Known Limitations / Design Decisions
- Container icons CANNOT be emoji in Firefox/Zen — used predefined strings (circle, fingerprint, briefcase, tree)
- Emoji icons appear on Spaces (Zen-specific workspaces), not on Firefox Containers
- Spaces and containers are INDEPENDENT — spaces are visual tab groupings; containers are cookie isolation
- pinsForce = true: undeclared pinned tabs will be deleted on rebuild — close Zen before rebuilding
- spacesForce = true: undeclared spaces will be deleted on rebuild — close Zen before rebuilding
- containersForce = true: undeclared containers will be deleted on rebuild
- search.force = true: only Kagi search engine will be available (all built-ins removed)
- keyboardShortcutsVersion = 17: if Zen updates and bumps version, rebuild will fail — bump in zen-browser.nix
