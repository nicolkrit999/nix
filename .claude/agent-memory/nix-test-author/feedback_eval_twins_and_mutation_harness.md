---
name: eval-twins-and-mutation-harness
description: extendModules twins over a mkForce'd variant need mkOverride <50; never bind `base` in scenarios (denix ext shadowing); leaked-WM twin for spec force-offs; formats.toml files readable via .source.value; scratch MUT-injection harness for mutation tests
metadata:
  type: feedback
---

- A twin `x.extendModules` that re-overrides an option the variant already `mkForce`d conflicts ("conflicting definition values"); use `lib.mkOverride 10`. Same for mutant modules layered under controls that `mkForce` the same option.
- `pkgs.formats.toml {}).generate` is runCommand with `__structuredAttrs` and `inherit value`, so an HM `xdg.configFile.<f>.source.value` gives the attrset at eval time, no build. Check presence via `.enable or false`, not `?`.
- nix-darwin `config.environment.systemPath` is a merged `:` string, not a list.
- Overlay origin without a build: `lib.hasPrefix "${input.outPath}/" pkg.meta.position` (fails if the overlay is dropped, unlike a version compare). Read the final module `pkgs` via a probe module `options.testProbe = mkOption { type = types.raw; }` (HM standalone `homeConfig.pkgs` is NOT the overlaid set).
- `writeShellScriptBin` scripts expose `.text` at eval; HM activation entries expose `.data` (run it in a temp HOME with `run` stubbed to a logger to test behavior store-free).
- Mutation harness that worked (2026-10-12): scratch copy of the scenario with `modules = (let m = builtins.getEnv "MUT"; in if m == "" then [ ] else [ (import m) ]) ++ [` injected into the variant's extendModules, one mutant module file per mutation, eval sequentially.

- Never name a scenario `let` binding `base` (or any denix extension name): `with denix.lib.extensions; [ (base.withConfig ...) ]` then resolves to the let binding -> "infinite recursion" pointing at `base.withConfig`.
- Spec force-off checks (e.g. `X.enable = mkForce false` in guest/secure-travel) are vacuous when the spec also forces the gating WMs off: add a twin `{ specialisation.<sp>.configuration.myconfig.programs.mango.enable = mkOverride 10 true; }` and assert X stays absent (plus a control re-enabling X). Mutation-proven 2026-10-14 (test-coffee).
- Fake hosts that load guest/secure-travel can declare the myconfig.*/stylix.* options those specs set as plain bool/raw sink options (plain NixOS module in the paths) instead of loading the real modules: ~13 s eval for 11 twins.

**Why:** a stopped agent lost time on the twin conflict; laptop RAM allows one eval at a time, so each wasted eval is costly.
**How to apply:** any scenario adding twins/controls over forced variants, and any mutation test round.
