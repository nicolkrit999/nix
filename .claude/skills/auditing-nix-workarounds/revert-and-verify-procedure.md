# Revert and verify procedure (Step 4)

Applies only to candidates confirmed fixed in the locked nixpkgs revision.

1. Dispatch `nix-config-architect` to remove the tweak and restore normal
   upstream behavior. Remove its explanatory comment with it: no orphaned
   comments and no new ones (this repo defaults to no comments; anything worth
   keeping goes in the memory file). If the revert touches cross-arch code,
   loop `nix-compat-checker` in alongside.
2. Dispatch `nix-checker` (flake check + relevant dry-builds, `--impure` on
   Darwin).
3. On failure, first decide whether the failure proves the tweak is still
   load-bearing or is an unrelated bug. Dispatch `nix-debugger` with the
   verbatim error, explicitly asking it to judge which case this is before
   touching anything.
   - **Failure traces back to the absence of the tweak** (research said safe,
     the build proves the upstream condition is not resolved): do not debug
     toward making the revert work. Dispatch `nix-config-architect` to
     restore the original tweak exactly as it was, then `nix-checker` to
     confirm green. Mark the candidate **reverted-then-restored** (not a plain
     "still needed": research said safe, the build proved otherwise).
   - **Failure unrelated to the tweak**: let `nix-debugger` fix it, re-verify
     via `nix-checker`, loop 2 -> 3 until green.
4. Safeguard: after ~4 rounds without convergence on an unrelated-bug failure,
   fall back to the restore path above, re-verify green, and note that
   convergence was not reached and why.
5. Never bump `stateVersion`. Never commit or push: the user rebuilds and
   tests on their own machine.
