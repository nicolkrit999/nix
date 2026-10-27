# Resource check (first step of every heavy skill)

Run `bash .claude/skills/_shared/resource-check.sh` (main loop, instant, read-only,
no nix evaluation) BEFORE dispatching any agent that builds, evaluates or runs
tests. It keys on measured hardware, never on the hostname: a future host with
different hardware gets the right budget automatically.

It prints `tier`, `max_parallel_agents`, `nix_flags` and `run_tests_parallel`,
computed from cores, available RAM, current load and `/tmp` headroom, with a
reserve of max(2, 25%) cores and max(4 GB, 25%) RAM always left free.

## How to apply the output

- **Agents:** never have more than `max_parallel_agents` heavy agents (anything that
  builds, evals or runs tests) alive at once; queue the rest and dispatch the next
  when one finishes. Light read-only/editing agents (researcher, linter, test
  author, architect) do not count. Hard ceiling for any audit batch: ~60 agents.
- **Builds/evals:** put the printed `nix_flags` (`-jN --cores M`) into every
  `nix build` brief and prefix with `nice -n 19`. Builds that are independent run
  sequentially when `tier=light`.
- **Test suite:** use `run-tests.sh --parallel` only when `run_tests_parallel=yes`
  (it peaked at ~52 GB unit / 59 GB system, ~7.8 GB per host eval, and `/tmp` was
  a 4 GB tmpfs). Otherwise run `--only <name>` one folder at a time.
- **Tiers:** `light` = one heavy agent, sequential, no fan-out. `medium` = 2-3.
  `heavy` = up to 8, still never the full suite plus separate builds at once if
  available RAM is below the sum of their peaks.
- **Pass the budget down:** quote the printed numbers in each heavy agent's brief
  so it also sticks to them. If the user says the machine is lagging, drop one tier
  and stop in-flight heavy agents rather than adding more.
- Re-run the script before each new batch; load and free RAM change while work runs.
