---
name: eval-twins-and-mutation-harness
description: extendModules twins over a mkForce'd variant need mkOverride <50; formats.toml files readable via .source.value; scratch MUT-injection harness for mutation tests
metadata:
  type: feedback
---

- A twin `x.extendModules` that re-overrides an option the variant already `mkForce`d conflicts ("conflicting definition values"); use `lib.mkOverride 10`. Same for mutant modules layered under controls that `mkForce` the same option.
- `pkgs.formats.toml {}).generate` is runCommand with `__structuredAttrs` and `inherit value`, so an HM `xdg.configFile.<f>.source.value` gives the attrset at eval time, no build. Check presence via `.enable or false`, not `?`.
- nix-darwin `config.environment.systemPath` is a merged `:` string, not a list.
- Overlay origin without a build: `lib.hasPrefix "${input.outPath}/" pkg.meta.position` (fails if the overlay is dropped, unlike a version compare). Read the final module `pkgs` via a probe module `options.testProbe = mkOption { type = types.raw; }` (HM standalone `homeConfig.pkgs` is NOT the overlaid set).
- `writeShellScriptBin` scripts expose `.text` at eval; HM activation entries expose `.data` (run it in a temp HOME with `run` stubbed to a logger to test behavior store-free).
- Mutation harness that worked (2026-10-12): scratch copy of the scenario with `modules = (let m = builtins.getEnv "MUT"; in if m == "" then [ ] else [ (import m) ]) ++ [` injected into the variant's extendModules, one mutant module file per mutation, eval sequentially.

**Why:** a stopped agent lost time on the twin conflict; laptop RAM allows one eval at a time, so each wasted eval is costly.
**How to apply:** any scenario adding twins/controls over forced variants, and any mutation test round.
