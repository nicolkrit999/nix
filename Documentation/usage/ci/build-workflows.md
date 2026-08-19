# 🏭 The CI build workflows

Companion to [`../cachix/cachix.md`](../cachix/cachix.md). That document explains
the *strategy* — the cloud is the factory, Cachix is the warehouse, your machines
are customers. This one explains the **machinery**: what the workflow files
actually do, why each awkward-looking decision is there, and what broke to put it
there.

---

## ⚠️ How to use this document

**This is a map, not the territory.** The workflow files are the truth; this
describes them as of the last time someone updated it, and code drifts.

Use it like this: read the relevant section first so you know *why* something is
the way it is, then **verify against the actual file** before acting. Knowing the
reason turns a blind search into a targeted one — that is the whole point of the
document. Nothing here should ever be quoted as authority against the file
itself.

If you change a workflow in a way that invalidates something below, update it in
the same commit.

---

## 1. The goal, in priority order

This ordering settles most design arguments. When two properties conflict, the
higher one wins.

1. **Push to Cachix as much as possibly works — including when the build
   fails.** A flake bump that breaks one package should still leave every other
   package cached, so pulling on a PC downloads almost everything and errors only
   on the broken one. You then fix it on that PC and rebuild.
2. **Run a flake check, and report problems to Discord.** A flake-check failure
   must *not* stop the build or the push. Build and push anyway.
3. **Everything else** — formatting, dead-code notices, package trees, disk
   reports — must never fail a job.

The failure mode that matters most, therefore, is not "a job went red". It is
**something was built and did not reach the cache**, or **something failed and
nobody was told**.

---

## 2. The workflows at a glance

| File | What it does | Runner | Job cap |
|---|---|---|---|
| `build.yml` | flake check, pre-warm, build both x86_64 hosts, push | `ubuntu-latest` | 120 / 120 / 350 / 10 <br>(`flake-check` / `prewarm-cache` / `build-x86_64` / `report`) |
| `build-darwin.yml` | flake check + build the Mac config, push | `macos-15` | 350 |
| `check-workflows.yml` | static analysis of the workflow files themselves | `ubuntu-latest` | 15 |
| `tests-nixos.yml`, `tests-darwin.yml` | the `templates/tests/` suite | both | 120 / 90 |
| `update-flake.yml` | weekly `nix flake update` → PR | `ubuntu-latest` | — |

Cache: **`krit-nixos`** (`CACHIX_NAME`, workflow-level env in both build files).

Triggers for the two build workflows are identical: `push` on `develop` and
`main`, `pull_request` (any branch), `workflow_dispatch`, and `schedule` at
`0 5 * * 5` (Fridays 05:00 UTC). `update-flake.yml` runs `0 4 * * 5` — an hour
earlier, so the bump PR exists before the weekly builds.

### `build.yml` job graph

```
flake-check ─┐
             │   (independent, runs in parallel)
prewarm-cache ──needs──> build-x86_64 (matrix: nixos-desktop, nixos-laptop)
             │                    │
             └────────────────────┴──needs──> report   (if: always())
```

- `build-x86_64` has `if: always()` on its `needs`, so a failed or skipped
  pre-warm leg never blocks the real build. Pre-warming is a pure speedup.
- `prewarm-cache` is **job-level `continue-on-error: true`**. Its own red status
  is therefore invisible in the workflow result — which is exactly how a broken
  push hid there for months (see §7, run 1111). It has its own per-leg notifier
  for this reason.
- `report` is a watchdog. See §6.4.

---

## 3. How the push actually works

There are **three layers**, and they exist because each one has a hole the next
one covers. ⚠️ **They are not applied uniformly** — which push step you are
looking at matters:

| Push step | Layer 1 `watch-exec` | Layer 2 targeted | Layer 3 whole-store |
|---|---|---|---|
| `build-x86_64` | ✅ | ✅ gated on build **outcome** + non-empty `outpaths.txt` | ✅ |
| `prewarm-cache` (per leg) | ✅ | ✅ but gated on `[ -s out.txt ]` **only**, no outcome gate | ✅ |
| `build-darwin` | ✅ | ❌ **none** — always whole-store | ✅ always |
| `flake-check` | ❌ | ❌ | ✅ |

Darwin always pushes the whole store on purpose: its job also runs the flake
check, and a targeted push would miss everything the check built.

### Layer 1 — `cachix watch-exec` (continuous, during the build)

The build command is wrapped in `cachix watch-exec`, which registers a Nix
**post-build hook**. Every store path is uploaded the moment it finishes
building, in parallel with the rest of the build.

This is the layer that matters most, because it is the **only one that survives
the runner dying** (§6.3). If the job is cancelled, times out, or the machine
disappears, whatever had already been built is already in the cache.

Two properties to know:

- Nix does **not** fire the hook for *substituted* paths. Only what was genuinely
  built on that runner is uploaded. That is desirable, not a bug.
- It is probed before use, and the probe is a **three-part conjunction** — the
  `Set up Cachix` step succeeded, `CACHIX_AUTH_TOKEN` is non-empty, and
  `cachix watch-exec --help` works. Any one failing drops to a plain build,
  because a Cachix problem must never be indistinguishable from a broken config.

### Layer 2 — the targeted push (fast path, clean builds)

If the build step's **outcome is `success`** and `outpaths.txt` is non-empty,
push exactly those paths.

Gating on the *outcome* rather than merely on the file being non-empty is
deliberate: `--keep-going` means the build can fail having realised plenty, and
`--print-out-paths` prints nothing in that case (the toplevel depends on
everything), so an emptiness test alone takes neither branch usefully.

**Only `build-x86_64` has this outcome gate.** The pre-warm legs use the
emptiness test alone (`if [ -s out.txt ]`), which is acceptable there because a
leg builds a single package rather than a whole system closure.

### Layer 3 — the whole-store fallback (salvage)

Any other outcome → `nix path-info --all`, filtered, pushed wholesale.

This is safe because **Cachix's upstream-cache filter is on by default**: paths
already present in `cache.nixos.org` are skipped. So this uploads what this repo
produced, not a copy of nixpkgs.

Two filters are applied:

- `.drv` files.
- `-self-test-` — the Determinate installer writes a path per run whose name
  carries a timestamp (`self-test-bash-1787097653189`). It is a brand-new store
  path every single run and nothing ever substitutes it, so left in it grows the
  cache without bound.

### 🔑 `pushed=0` is normal, not a failure

On a warm run everything substitutes from `cache.nixos.org`, the upstream filter
skips it all, and the notifier records `pushed=0`. **This is the expected result
of a healthy warm run.** It is reported as a `note` (⚪) that rides along in a
message being sent anyway, never as a trigger.

Corollary for debugging: searching a store path on the Cachix website and finding
nothing does **not** mean pushing is broken. If that path is in
`cache.nixos.org`, it was correctly skipped. Look for a path that only this repo
produces (an `activation-krit`, a host toplevel) instead.

---

## 4. The Nix-level configuration, and why it differs per platform

### 🚨 The GC asymmetry — read this before "fixing" it

This is the single most re-litigated decision in the repo. **It is deliberate.**

| | `build.yml` (Linux) | `build-darwin.yml` (macOS) |
|---|---|---|
| `min-free` / `max-free` | ❌ absent | ✅ 5 GB / 15 GB |
| `keep-outputs` / `keep-derivations` | ✅ `true` | ❌ absent |
| Store cache to protect? | ✅ yes | ❌ no |
| Free space at start | ~78 GiB (via `nothing-but-nix`) | ~40 GiB, hard ceiling |

**Why Linux keeps and does not collect.** `keep-outputs`/`keep-derivations` stop
a saved store cache from referencing pruned files — the `user-environment.drv
does not exist` failure of 2026-07-07. Auto-GC would work against that.

**Why adding auto-GC to Linux would be actively worse.** The build uses
`--no-link`, so there are **no GC roots**. Auto-GC collects unreferenced paths —
and with no roots, a just-built toplevel is unreferenced. It could be deleted
*before the push runs*, which is a worse failure than the disk pressure it would
relieve. If auto-GC is ever genuinely needed on Linux, `--no-link` has to go
first so the outputs have roots.

**Why Darwin can afford it.** No store cache to protect, and anything GC removes
was already uploaded by `watch-exec`, so the worst case is re-substituting from
our own cache. Run 754 filled the disk (1.4 GiB free, 100% full) and then
produced nothing for five hours until the step timeout killed it.

**The limit of the reasoning.** The "~78 GiB is plenty" argument was sized for
**one** system closure. It does not hold for two — see run 1111 in §7.

### Substituters

CI configures the same six extra substituters the machines trust
(`modules/nixos/toplevel/nix-nixos.nix`): hyprland, cosmic, walker, claude-code,
vicinae, catppuccin. Darwin gets only claude-code and catppuccin — the rest are
Linux-only and each extra substituter costs a narinfo round-trip per path.

⚠️ This is **not** covered by `--accept-flake-config`. The builds never pass that
flag (only `nix profile install nixpkgs#cachix` does), so an input flake's own
`nixConfig.extra-substituters` is ignored regardless. Without this block CI
*compiles from source* what every machine simply downloads.

### The store cache (`cache-nix-action`)

- **One saver, two restorers.** Only `build-x86_64` saves; `flake-check` restores
  only. The two jobs therefore never race on cache writes.
- **Key shape:**
  `nix-<os>-<hashFiles(flake.lock)>-<matrix.host>-<run_id>-<run_attempt>`.
  - The lock hash comes **before** `matrix.host` on purpose, so `flake-check`'s
    same-lock prefix `nix-<os>-<lock>` still matches. Putting `matrix.host` first
    silently breaks that — a cache miss is not an error, the job just runs cold
    forever. Guarded by the `cache-prefix-match` invariant (§8).
  - `run_id`/`run_attempt` make every attempt save a fresh cache. A key that is
    only the lock hash can never be updated once it exists, so a first failed
    attempt would freeze its partial store permanently.
  - Restoration is **same-lock only**. The old catch-all `nix-<os>-` fallback
    pulled in stores from arbitrary older runs; `cache-nix-action` *merges* the
    restored `db.sqlite` into the live one, so stale rows became phantom "valid"
    entries for paths the archive never carried.
- `Verify Restored Store` runs `nix-store --verify --repair` at restore time.
  `--repair` is load-bearing: plain `--verify` leaves a missing path registered
  whenever something still refers to it, so Nix keeps trusting the db and never
  re-substitutes.
- `auto-optimise-store` is **off on Linux** (`build.yml`), because the hardlink
  farm under `/nix/store/.links` does not survive the cache archive round-trip
  and this is the job that *saves* the cache. Darwin turns it **on**
  (`build-darwin.yml:44`) — it has no store cache to round-trip, so the dedupe is
  a free disk saving on a machine whose ~40 GiB ceiling is the binding
  constraint.
- The save step is **not** `always()`. A cancelled run snapshots a store whose db
  references paths the tar never captured. This is the one deliberate difference
  from the Cachix push, which *is* `always()`: Cachix uploads whole valid paths
  one at a time, so a truncated push means fewer paths, never a corrupt cache.

---

## 5. The pre-warm matrix

Eight packages, each on its own runner, before the main build:

`vscode`, `obs-studio`, `libreoffice-qt`, `teams-for-linux`, `vesktop`,
`signal-desktop`, `tor-browser`, `thunderbird`

Built as `.#nixosConfigurations.nixos-desktop.pkgs.<attr>`, **not** plain
`nixpkgs#<attr>`, so it is the exact derivation the real build would use —
same overlays, same unfree allowance, same system — not a look-alike from a
different `pkgs` instantiation.

**What the matrix is for.** Not "making sure these get cached" — the main build
pushes them anyway. It is for **Hydra-lag windows**: when nixpkgs has bumped
ahead of Hydra, these large packages have no upstream binary and must be built.
Doing that on eight parallel runners keeps it out of the build job's budget.

**The bar for adding one is evidence, not intuition.** Every entry is here
because a log showed it being *built* rather than substituted. `thunderbird` was
added because run 754 spent its entire 300-minute budget compiling
`thunderbird-unwrapped`. Adding legs on suspicion costs runner minutes and adds
notification noise for no proven gain.

### 🚨 Do not pre-warm a flake-input package by name

`tgt`, `concord` and `herdr` come from `inputs.<x>.packages.<system>.default`, so
the derivation the config installs is **not** the `pkgs` attribute of the same
name. The trap is that two of those attributes *exist anyway* in the pinned
`nixos-26.05`, and are different software — so `.pkgs.<name>` does not error, it
silently builds and caches the wrong thing:

| Name | What the config installs | What `pkgs.<name>` is in nixos-26.05 |
|---|---|---|
| `tgt` | `github:FedericoBruzzone/tgt` — a Telegram TUI | **tgt 1.0.95, the iSCSI Target daemon** — unrelated |
| `concord` | `github:chojs23/concord` | **concord 2.3.0, a Discord API library in C** — unrelated |
| `herdr` | `github:ogulcancelik/herdr` tracking **master** | *absent* from nixos-26.05 — this one does fail cleanly with *attribute missing*. (It exists in `unstable` as 0.8.0, the same project, so this trap appears the moment the channel moves.) |

`concord` is additionally wrapped in `.overrideAttrs` in
`modules/nixos/programs/concord.nix`, so even the correct input is not the
derivation the system uses.

`doom` is not a package at all — it is a home-manager module
(`programs.doom-emacs`, from `nix-doom-emacs-unstraightened`), so it has no
`pkgs` attribute to name. It *is* reachable through the config tree without
touching `flake.nix`. See §10.

---

## 6. Failure semantics — the four hard-won rules

### 6.1 `continue-on-error` makes a failed step report success

A step with `continue-on-error: true` has `conclusion == 'success'` **even when
it failed**. Only `outcome` holds the truth, and only a later step can read it
via `steps.<id>.outcome`.

This is how the pre-warm push failed on every leg of every run for months while
the job stayed green. Any check written against `.conclusion` on such a step is
dead code. Guarded by the `outcome-not-conclusion` invariant.

### 6.2 A step with no status function is skipped once the job has failed

Every push step is `if: always() && ...`. Without `always()` the push is skipped
precisely when the build failed — which is when there is the most to salvage.
Guarded by the `push-always` invariant.

### 6.3 `always()` does **not** survive the runner dying

This is the important one, and it is not intuitive.

`always()` covers a failed step, a timed-out step, and a cancelled run — for
cancellation there is a grace window of roughly **eleven minutes** in which
`always()` steps really do execute (observed in run 1095).

It does **not** cover the runner itself dying. There is nothing left to run the
step. The signature is unmistakable: the job's conclusion is `failure`, the build
step is still marked `in_progress`, the push step is still marked `pending`, and
the logs return **HTTP 404** because they were never uploaded.

Two consequences:

- `watch-exec` (§3, layer 1) is not a nice extra. It is the **only** protection
  against this case.
- Keeping each job inside a resource envelope a runner survives is a
  **push-reliability measure**, not a performance tweak. That is why the two
  x86_64 hosts build on separate runners.

### 6.4 A dying runner cannot notify you about itself

Every in-job notifier lives inside the job it reports on, so the worst failure
the workflow can suffer was also the only one that was silent.

The `report` job exists for this. It runs on its **own runner**, `needs` the
other three, is `if: always()`, and reads `needs.<job>.result` — which GitHub
fills in however the job ended. It stays quiet when every job reached a normal
end, so a green run is still silent.

### Ordering inside a job

Nothing that merely prints information may run before the steps that persist
something. Order is: **push → save cache → disk → package tree → notify.**

`du -sh /nix/store` is banned before the push: it walks the whole store, took
over ten minutes on a 32 GB store in run 1095, and burned the entire grace window
before being SIGTERM'd (exit 143). `df -h /nix` reports the same actionable
number instantly. Guarded by the `grace-window` invariant.

### What gates the push

Push steps are gated on `steps.cachix_setup.outcome == 'success'`. That step
installs the cachix CLI **and** runs `cachix use`. `cachix use` configures a
*substituter* — it is about downloading and has nothing to do with pushing — so
it is deliberately **non-fatal** and only warns. Making it fatal means a
transient substituter-config hiccup silently disables all pushing with a
perfectly valid token.

---

## 7. Incident log

The cheapest way to avoid re-deriving all of this. Each entry: what happened →
what it changed.

| Run / date | What happened | Outcome |
|---|---|---|
| 2026-07-07 | `user-environment.drv does not exist` on a restored cache — db rows pointing at files the archive never carried | `keep-outputs`/`keep-derivations`; `nix-store --verify --repair` at restore; same-lock-only restore prefixes |
| 2026-07-08 | `Error: not found: cachix` failed a whole job | Pushing is `continue-on-error` everywhere — a Cachix outage must never fail a build |
| **754** (darwin) | Built `thunderbird-unwrapped-153.0.1` in a Hydra-lag window, filled the disk (1.4 GiB free, 100%), then produced nothing for five hours until the step timeout | Darwin auto-GC (`min-free`/`max-free`); `thunderbird` added to the pre-warm matrix |
| **1095** | `du -sh /nix/store` consumed the whole ~11-minute cancellation grace window, SIGTERM exit 143, push never ran. Same run showed `vicinae-0.25.0` compiled from source despite vicinae publishing a cachix | `df` instead of `du`; the six extra substituters added to CI |
| **1110** | Baseline, desktop only, warm | build **12m44s**, push 9s, cache save 2m36s, job 19m41s |
| **1111** | Both hosts in one `nix build`. Runner died at 68 min; build step stuck `in_progress`, push step `pending`, logs 404. Nothing pushed, and no notification | One host per runner (matrix); the `report` watchdog job |
| **1111** (pre-warm) | Confirmed on the wire: `env: CACHIX_TOKEN: ***` then `Neither auth token nor signing key are present.` and exit 1 — reported by GitHub as step `conclusion: success` | `CACHIX_AUTH_TOKEN` set wherever cachix writes; `cachix-auth` invariant |
| **1115** | Auth fix validated: `outcome=success`, `pushed=0`, notifier silent on all 8 legs | — |

### The 1111 lesson, stated plainly

Adding `nixos-laptop` to the same `nix build` was justified as "the laptop's
marginal cost is only its host-specific derivations". Measured, that is false:
12m44s → died at 68 minutes. With `keep-outputs` retaining every *intermediate*
output, two closures do not fit in the headroom sized for one.

---

## 8. The invariant checker

`.github/scripts/check-workflow-invariants.py`, run by `check-workflows.yml` on
pushes to `develop`/`main` and on **any pull request** that touches
`.github/workflows/**` or `.github/scripts/**`, plus weekly (`0 6 * * 1`) and on
manual dispatch. The `pull_request` trigger has no branch filter, which is why it
runs on feature branches.

```bash
python3 .github/scripts/check-workflow-invariants.py
```

**Every invariant is a bug that actually happened here**, tagged with the run
that exposed it. It is deliberately *not* a general-purpose linter — actionlint
covers that. It protects the one property a generic tool cannot know about: what
gets built must reach the cache, and failures must not be silent.

Current checks: `cachix-auth`, `push-always`, `push-non-fatal`, `step-ref`,
`outcome-not-conclusion`, `pipefail`, `bash-c-newline`, `grace-window`,
`matrix-cache-key`, `notify-guard`, `notify-non-fatal`, `webhook-curl-fail`,
`cache-prefix-match`.

**If you add a check, mutation-test it** — reintroduce the bug in a temp copy and
confirm the checker fails. A check that cannot fail is worse than no check,
because it reads as coverage.

`actionlint` runs alongside it, gated on its own analysis with **shellcheck
advisory only**. Several shellcheck findings here are deliberate:
`cachix push <cache> $(cat out.txt)` relies on word splitting to turn one path
per line into one argument per path, and quoting it as SC2046 asks would pass the
whole file as a single argument and break every push.

---

## 9. Shell and Actions gotchas that have bitten this repo

- **`bash -e` without `-o pipefail`.** GitHub runs `run:` blocks with `bash -e`
  only. A pipe into `tee` or `cachix` reports the *last* command's status, so an
  upstream failure is masked and the step reports success having done nothing.
  Add `set -o pipefail` in any step that pipes. (`pipefail` invariant.)
- **`[ test ] && cmd` as the last command of a step.** When the test is false the
  list returns non-zero and the step fails. Notifiers therefore append findings
  inside `if` blocks, never with `&&`.
- **`bash -c` treats bare newlines as separate commands.** It does not stop after
  the first line — it executes *every* line as its own command. A multi-line
  single-quoted `BUILD='nix build …'` variable nearly shipped this way: the first
  line would have run `nix build` with no arguments, and each following line
  would then have been run as a command in its own right. Use backslash
  continuations. (`bash-c-newline`.)
- **Cross-job step references evaluate to `''` silently.** `steps.<id>.*` for an
  id not declared in the *same* job does not error. (`step-ref`.)
- **Matrix legs share `run_id` and `run_attempt`.** A cache key that does not
  name the matrix variable collides between legs of the same run.
  (`matrix-cache-key`.)
- **`curl -s` exits 0 on HTTP 4xx/5xx.** A rotated webhook token looks exactly
  like a delivered notification. Use `--fail`. (`webhook-curl-fail`.)
- **`grep -c` exits 1 on zero matches** under `-e`; the `|| true` on the
  `pushed=` lines is load-bearing.
- **GitHub's queue.** Runs can sit `pending` for 20+ minutes. Observed: an older
  in-progress run continuing while newer runs in the same concurrency group were
  cancelled, and the newest held `pending` until the old one ended. Be patient
  before concluding something is broken.

---

## 10. Open questions and things not yet verified

Keep this section honest — it is what stops the next person re-testing settled
things and trusting unsettled ones.

- 🔴 **`watch-exec` has never been observed uploading mid-build.** It is
  confirmed to *engage* (`Building under 'cachix watch-exec'`, run 768), but
  every run so far has been warm, so there has been nothing to upload. Since it
  is the only protection against runner death (§6.3), this is the most valuable
  thing left to confirm. It needs a **cold** run — a flake bump changes
  `flake.lock`, which changes the store-cache key, which misses the cache
  entirely. Look for `Pushing /nix/store/…` interleaved with
  `building '/nix/store/…'`, not only at the end.
- 🟠 **Per-host build timings after the matrix split are unmeasured.** Baseline to
  beat is run 1110's 12m44s for the desktop alone. The laptop's true marginal
  cost is still unknown — run 1111 died before finishing, so the only honest
  statement is "more than assumed".
- 🟠 **Whether `tgt` / `doom` are worth pre-warming is unmeasured.** Both would
  need work to be addressable (§5): `doom` is reachable through the existing
  config tree without touching `flake.nix`, `tgt` would need a single-system
  `packages` output. Do not add either until a log shows it being *built* rather
  than substituted. A general `packages` output re-exporting flake inputs is a
  bad idea: `concord` is used via `.overrideAttrs`, so a plain re-export is a
  *different derivation* and pre-warming it would cache a path the build never
  substitutes.
