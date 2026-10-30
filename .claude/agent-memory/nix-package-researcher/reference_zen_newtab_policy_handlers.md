---
name: zen-newtab-policy-handlers
description: Zen 1.24b (locked beta) honours Firefox Homepage/FirefoxHome/NewTabPage policies verbatim via policies.json; zen.urlbar.replace-newtab makes Ctrl+T a floating URL bar. Source-verified.
metadata:
  type: reference
---

Zen beta locked at 1.24b (zen-browser flake input, sources.json). `programs.zen-browser.policies` is HM `attrsOf jsonFormat.type` (home-manager mkFirefoxModule.nix) and is written verbatim to `distribution/policies.json` of the unwrapped package, so Firefox policy keys reach Gecko unchanged.

Verified in browser/omni.ja `modules/policies/Policies.sys.mjs` (extracted from the 1.24b store path):
- `FirefoxHome.{Search,TopSites,SponsoredTopSites,Highlights,Pocket,Stories,SponsoredPocket,SponsoredStories,Weather,Widgets.{Enabled,Blocked}}` map to activity-stream prefs (showSearch, feeds.topsites, showSponsoredTopSites, feeds.section.highlights, feeds.section.topstories, showSponsored, showWeather + widgets.weather.enabled, widgets.enabled). `Snippets` has no handler in this build.
- `Homepage.{URL,StartPage,Locked,Additional}`; StartPage "none" -> about:blank. Default homepage pref is about:home.
- `NewTabPage` (bool) -> browser.newtabpage.enabled locked.

Zen-native: `zen.urlbar.replace-newtab` (default true) makes Ctrl+T open a floating URL-bar popup instead of about:newtab (ZenUrlbarController.mjs). `zen.urlbar.open-on-startup` default true.

Why: user wants search-only new tab/home. Why source-checked: policy keys are not typed by the HM module, so typos fail silently.

How to apply: for any future Zen homepage/newtab question, start here rather than re-extracting omni.ja. Re-verify if the locked zen-browser rev moves past 1.24b.
