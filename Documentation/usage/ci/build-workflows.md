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
| `build.yml` | flake check, pre-warm, build both x86_64 hosts, push | `ubuntu-latest` | 120 / 60 / 180 / 10 <br>(`flake-check` / `prewarm-cache` / `build-x86_64` / `report`) |
| `build-darwin.yml` | flake check + build the Mac config, push | `macos-15` | 180 |
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

### ⏱️ Timeout budget

Every cap is deliberately well under GitHub's 360-minute hard kill, and the
**serial** chain is what matters: `prewarm-cache` (60) runs before
`build-x86_64` (180) via `needs:`, so the critical path is **240 minutes**, not
the sum of every job.

| | job cap | build-step cap |
|---|---|---|
| `flake-check` | 120 | — |
| `prewarm-cache` | 60 | 45 per leg |
| `build-x86_64` | 180 | 150 |
| `report` | 10 | — |
| `build-darwin` | 180 | 150 |

Each build-step cap leaves a tail inside its job cap for the push, the cache save
and the notifier.

#### The real GitHub ceilings, and a number that is easy to misread

| Limit | Value | What happens |
|---|---|---|
| Job execution time (GitHub-hosted) | **6 hours / 360 min** | the job is **hard-killed** — post-steps do not run, so the cache save is lost |
| Workflow run total | 35 days | run is cancelled |
| Queue wait | 24 h | run is dropped |

⚠️ **There is no 300-minute GitHub limit.** That number looks real because run 761
died at ~306 minutes, but it was *our own* cap: `build-darwin.yml` had
`timeout-minutes: 300` on the build step, and the step failed at **300.23 min**,
on the dot. The job then kept running for a further **3.3 minutes** of post-steps
and finished normally — which is the proof that GitHub had not killed it.

The distinction matters when choosing caps. A *step* timeout is orderly: later
steps still run, so the push and the cache save happen. Only the **360-minute
job** kill is catastrophic, because nothing runs afterwards. Our caps are set to
stay clear of that, not of 300.

**A tight cap is safe here, and that is not obvious.** Hitting a timeout is not
data loss: `watch-exec` has already uploaded every path as it was built, and the
store cache still saves on a timeout (the save step runs on failure, just not on
cancellation). So the next run resumes further along the dependency chain —
progress is monotonic across runs. Two bounded runs beat one five-hour run that
risks the hard kill, which *would* lose the cache save.

---

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

#### It now proves itself on every run

Because this property was repeatedly *unprovable* by hand (see §11), each
watch-exec build tees its output to `watch.log`, and a
**`Report Continuous Push (watch-exec)`** step (`if: always()`,
`continue-on-error`) counts and publishes two step outputs:

| output | counted from | meaning |
|---|---|---|
| `streamed` | `^Pushing /nix/store/` | paths the post-build hook uploaded **during** the build |
| `built`    | `^building '/nix/store/` | derivations actually compiled on this runner |

The alarm is the point of the step:

- `built > 0` **and** `streamed == 0` → `::warning::` — continuous push is broken.
  This is the genuinely bad state, and it is **invisible without this check**,
  because the layer-3 backstop silently covers for it.
- `streamed == 0` with `built == 0` → normal warm run, stays quiet.

⚠️ `set -o pipefail` before that pipe is **mandatory, not stylistic**: under the
default `bash -e` shell `false | tee` exits **0**, so without it a failing build
would be reported as green. Guarded by the `pipefail` invariant (§8).

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

#### The count was inflated by one until 2026-08-19

`cachix push` prints a **summary header** — `Pushing 14 paths (2089 are already
present) using zstd to cache krit-nixos` — as well as one `Pushing /nix/store/…`
line per path. The old `grep -c '^Pushing '` matched both, so `pushed` was always
`N+1` whenever anything was uploaded. Run 1136's flake-check uploaded exactly
**14** paths and reported `pushed=15`.

All six push steps across both workflows shared the bug. It survived several runs
because the **zero case was always correct** — with nothing to upload cachix
prints `Nothing to push - all store paths are already on Cachix.` and no
`Pushing` line at all — so the "0 pushed after a failed build" alarm never fired
on it. A bug that only manifests when things are working hides well.

Counting is now anchored on the store path (`^Pushing /nix/store/`) and guarded
by the `push-count-anchored` invariant (§8).

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

`always()` covers a failed step and a timed-out step.

⚠️ **On cancellation it is not reliable.** Two runs behaved completely
differently:

- Run 1095 got a grace window of roughly **eleven minutes**, in which `always()`
  steps really did execute (and `du -sh /nix/store` ate all of it).
- Run 1115 was cancelled by the concurrency group and its `always()` push step
  was marked **`skipped`**. The whole job wrapped up in **under one second**.
  27 minutes of work, no salvage push.
- Darwin run **796** (2026-08-19) was cancelled after 2h09m and the **entire
  `always()` tail executed**: `Push to Cachix (Darwin)` 19:09:21→19:09:25,
  then `Check Disk Usage`, `Show Package Tree`, `Report Job Status` and
  `Notify (darwin)`, job done at 19:09:37. Post-job cleanup even reaped a live
  `cachix` orphan (`Terminate orphan process: pid (7051) (cachix)`).

So a cancellation may or may not give you a window. Design for the worst case:
`watch-exec` is what actually protects a cancelled run, and **avoiding
unnecessary cancellation matters** — every push to a branch with a run in flight
discards that run's remaining work.

It also does **not** cover the runner itself dying. There is nothing left to run the
step. The signature is unmistakable: the job's conclusion is `failure`, the build
step is still marked `in_progress`, and the push step is still marked `pending`.

⚠️ **Correction (2026-08-19): the logs do not 404 — they are TRUNCATED.** They
return the portion uploaded before the runner died, which can end 30-60 minutes
before the death, with no error line at all. Of the four cold deaths that day,
only one (run 1137's laptop) had a visible cause:

```
##[error]Process completed with exit code 143.
##[error]The runner has received a shutdown signal. This can happen when the
         runner service is stopped, or a manually started runner is canceled.
Terminate orphan process: pid (5106) (cachix)
```

Two variants exist, and they are not the same thing:

| variant | later steps | seen in |
|---|---|---|
| runner simply gone | still `pending` — never evaluated | 1136 laptop + desktop, 1137 desktop |
| shutdown signal | `skipped` — `always()` evaluated to false | 1137 laptop |

Neither runs the push. `Terminate orphan process: … (cachix)` in the second shows
`watch-exec` was alive to the last moment.

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
| **1122** | ✅ **First fully green matrix run.** `nixos-desktop` build **10m35s**, push ran (6s); `nixos-laptop` build **10m55s**, push ran (1s); both in parallel, **17m18s wall clock for the pair** — faster than run 1110's 19m41s for the desktop *alone*. Every step green on both legs | Confirms the matrix split; the laptop is effectively free in wall-clock terms |
| **1133** (cold) | `nix flake check` failed on a missing `ffmpeg_9` attribute after a flake bump — **yet the pushes still ran**: flake-check built 5 derivations and pushed 22 paths (1808 already present) | Confirms the "push what worked even when something failed" design end-to-end |
| **794** (darwin) | `##[error]The action 'Build Darwin Configuration' has timed out after 150 minutes.` — then **2h11m** of nothing but `running auto-GC to free 13525108224 bytes` / `deleting garbage…` | First evidence the macOS runner **GC-thrashes under disk pressure** during a long compile; a longer cap may not help (§11.4) |
| **796** (darwin) | Cancelled after **2h09m42s** having built exactly **one** derivation (`firefox-unwrapped-154.0`) that never finished. Entire `always()` tail still ran | Refines §6.3 — a cancellation *can* give a full grace window |
| **1136** (cold) | flake-check green in 4m07s on a genuine cache miss; **`pushed=15` reported for exactly 14 uploaded paths** | Exposed the push-count off-by-one at all six sites → fix + `push-count-anchored` invariant (§3) |
| **1136 / 1137** (cold) | 🔴 **Four cold Linux runner deaths in one evening**, one host per runner, at 70.5 / 108.5 / 28.7 / 76.5 min — none reaching its 150-min cap. `Push to Cachix` never ran on any of them | Reopened the matrix-split fix: it was only ever validated warm. No salvage push and no store-cache save on a cold build |
| **1139** (cold) | flake-check green at `ace17ce` in 2m59s; all 8 pre-warm legs green and the new `Report Continuous Push` step observed printing `streamed 0 / built 0` with no false alarm | Validates the self-proving instrumentation and the anchored push count end-to-end |
| **1115** (pre-warm) | Auth fix validated: `outcome=success`, `pushed=0`, notifier silent on all 8 legs | — |
| **761** (darwin, on `main`) | Build step hit its own `timeout-minutes: 300` at 300.23 min and failed. The job then ran post-steps normally for 3.3 min — GitHub did not kill it. **`Push to Cachix` was `skipped`**, because `main`'s gate is `if: steps.build.outcome == 'success'` with no `always()`. Five hours of building, nothing cached | The `always()` push gate, fixed on `develop`. `main` still has the old gate |
| **1115** (build) | Cancelled by the concurrency group after 27 min. `always()` push step **skipped**, job over in <1s. Log shows 38 `copying path`, **zero** `building` lines, last output at 11:12 then silence — it was still *evaluating*, with repeated `builtins.derivation … options.json` (IFD) warnings | §6.3 rewritten: `always()` is not reliable on cancellation |

### `main` lags `develop` on purpose

`main` still carries the pre-fix workflows — `build-darwin.yml` caps of 300/350
and a push gated on `steps.build.outcome == 'success'` with no `always()`, the
combination that lost five hours in run 761.

**This is known and accepted, not a gap to fix.** `develop` is where the
workflows are stabilised; the owner promotes to `main` by hand once satisfied,
and that single merge brings every fix across at once. No Nix code is being
changed on `main` in the meantime, so the stale workflows there are not building
anything that matters.

Do not "helpfully" open a PR against `main` to sync it.

### The 1111 lesson, stated plainly

Adding `nixos-laptop` to the same `nix build` was justified as "the laptop's
marginal cost is only its host-specific derivations". Measured, that is false:
12m44s → died at 68 minutes.

✅ **Confirmed by run 1122 — but only for WARM runs.** One host per runner, and
both build in **10m35s / 10m55s** in parallel — 17m18s wall clock for the pair,
against 19m41s for the desktop alone before. So the cost was never the laptop's
*content*; it was putting two configurations through a single `nix build`.

🔴 **REOPENED 2026-08-19: the split does NOT save a COLD build.** Run 1122 was
warm. On genuinely cold builds the runner still dies, one host per runner:

| run | leg | build window | elapsed | how |
|---|---|---|---|---|
| 1136 | laptop | 18:30:06 → 19:40:36 | 70.5 min | runner gone, later steps never ran |
| 1136 | desktop | 18:28:43 → 20:17:12 | 108.5 min | runner gone, later steps never ran |
| 1137 | laptop | 20:23:31 → 20:52:12 | 28.7 min | exit 143 + shutdown signal, later steps skipped |
| 1137 | desktop | 20:24:27 → 21:40:56 | 76.5 min | runner gone, later steps never ran |

None reached its 150-minute step cap. **The consequence hits the primary goal
directly**: `Push to Cachix` never runs, so there is no salvage push, and
`Save Nix Store Cache` never runs either, so the next run starts cold again — a
death loop that explains why every run that week began from nothing.

That makes `watch-exec` (§3, layer 1) not merely the most important push layer on
a cold build but the **only** one that can work — and §11.2 is still open on
whether it does.

⚠️ **Cause not established.** The obvious hypothesis is resource exhaustion on
`ubuntu-latest` with `--max-jobs 2 --cores 4`, but **no OOM or ENOSPC line has
ever been observed**: the logs truncate long before the death (§6.3) and the
full-run ZIP is unreachable. Four deaths with one visible cause line is not a
diagnosis. Do not record it as one.

⚠️ **The underlying mechanism is still not confirmed.** The first hypothesis was disk exhaustion:
`keep-outputs` retains every *intermediate* output, and the ~78 GiB headroom was
sized for one closure. Run 1115 does **not** support that. Building the same two
hosts, it logged 38 substitutions and **zero builds** in 27 minutes, still inside
evaluation, emitting repeated IFD warnings for `options.json`. Nothing had been
built, so nothing could have filled the disk.

What is solid: **two hosts in one `nix build` is dramatically more expensive than
one, and the cost lands before the build phase.** Evaluation is single-threaded
and holds both configurations in one evaluator process, and IFD serialises it
further. One host per runner is therefore the right fix either way — it halves
both the evaluation work and the evaluator's peak memory. Do not write the disk
explanation back into the code comments until something actually measures it.

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
`cache-prefix-match`, `push-count-anchored`.

As of 2026-08-19 that is **137 assertions** across 6 workflow files (the count
scales with the number of matching steps, not the number of check names).

**If you add a check, mutation-test it** — reintroduce the bug in a temp copy and
confirm the checker fails. A check that cannot fail is worse than no check,
because it reads as coverage. `push-count-anchored` was mutation-tested against
both a bare `'^Pushing '` and a subtly-short `'^Pushing /nix/'`; `pipefail` was
re-mutation-tested against the new `watch.log` pipe.

⚠️ **`cachix-auth` matches the literal text `cachix push` / `cachix watch-exec`
anywhere in a step's `run:` block, including inside an `echo`.** That strictness
is deliberate — it errs toward demanding the token. If a new step merely *talks*
about watch-exec, reword the message rather than weakening the check or handing a
secret to a step that does not need one. (This is why the
`Report Continuous Push` fallback message says "continuous push (watch-exec)"
instead of naming the command.)

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
- **A newer run does NOT displace a running one.** `cancel-in-progress: true`
  cancels *pending* runs in the group; a run already `in_progress` keeps going
  and the newcomer queues behind it. Observed repeatedly (1111 vs 1112-1114,
  1130 vs 1131/1132). So a stuck job blocks every later run on the same ref.
- **`if: always()` at JOB level survives run cancellation.** When run 1130 was
  superseded, its `flake-check` and all 8 pre-warm legs were cancelled — and its
  two `build-x86_64` legs were created **7 seconds later** and ran to completion
  anyway, because that job carries `if: always()`. Useful, but it means a
  cancelled run can still hold the concurrency slot for hours.
- **A hung step is not a failed step.** `continue-on-error` and `|| true` cover a
  command *failing*; neither covers it *hanging*. Run 1130's `Install CA
  Certificates` stalled on an unreachable apt mirror for 27+ minutes, and
  because the runner itself was unreachable a manual **Cancel could not be
  delivered** — the job was unkillable until its 180-minute cap. Anything that
  can block on the network needs `timeout-minutes`. Guarded by the
  `package-manager-timeout` invariant.
- **Escaping a blocked concurrency group:** the group is
  `workflow + github.ref`, so a run on a *different* ref is unaffected. Opening a
  PR from a branch at the same commit gets a build on `refs/pull/N/merge` and
  starts immediately, without waiting for the stuck run on `develop`.
- **`list_workflow_runs` with a `branch` filter can return STALE data** — it
  served two-week-old runs repeatedly while today's were live. Query without the
  filter and sort client-side by `created_at`.
- **GitHub's queue.** Runs can sit `pending` for 20+ minutes. Observed: an older
  in-progress run continuing while newer runs in the same concurrency group were
  cancelled, and the newest held `pending` until the old one ended. Be patient
  before concluding something is broken.

---

## 10. ⚠️ Things only a human can do

Automation cannot resolve these. If one is blocking, it needs the repo owner.

| Situation | Why automation cannot | What the owner needs to do |
|---|---|---|
| Cancelling a workflow run | The session token has no `actions: write`; `POST /actions/runs/:id/cancel` returns **403**. | Cancel from the Actions tab. |
| **Triggering any `workflow_dispatch`** | Same missing permission: `POST /actions/workflows/:id/dispatches` returns **403**. An automated session cannot start `update-flake.yml`, nor manually dispatch `build.yml` / `build-darwin.yml` against a branch. | Actions tab → pick the workflow → **Run workflow**. |
| Producing a `flake.lock` bump by hand | There is no Nix in the session container, so `nix flake update` cannot be run locally either. Combined with the row above, a flake bump is entirely owner-or-schedule driven. | Run **Update Flake Lockfile** from the Actions tab, or wait for the Friday 04:00 UTC cron. |
| Rotating `CACHIX_AUTH_TOKEN` or the Discord webhook secrets | Repository secrets are write-only to CI and unreadable from a session. | Update under Settings → Secrets. |
| Cachix storage running out | The cache's quota is an account-level setting. | Raise the plan, or `cachix gc`. |
| Giving CI access to the NAS / `attic` | The NAS is Tailscale-only and CI is deliberately not on the tailnet — see the note in the cachix doc. **This is a decision, not a gap. Do not "fix" it.** | Nothing — it is intentional. |
| Merging to `main` | `develop` is the integration branch; promotion to `main` is a human call. | Merge when satisfied. |
| Approving a flake-update PR | A dependency bump is a judgement call about what the machines will run. | Review and merge. |

**Anything an automated session cannot finish should be recorded here rather than
left in a chat message**, because chat scrollback is not something a future
session can rely on reading.

## 11. Open questions, current state, and what is left to do

Keep this section honest — it is what stops the next person re-testing settled
things and trusting unsettled ones. **If you are a session that has lost its
context, start here.**

### 11.1 State as of 2026-08-19 20:00 UTC

Branch `develop` @ `469ba73`. Two commits landed this evening:

| commit | what |
|---|---|
| `05337d4` | push-count off-by-one fixed at all six sites + invariant `push-count-anchored` |
| `469ba73` | `Report Continuous Push (watch-exec)` self-proving step on all three watch-exec builds |

Settled today, with evidence:

- ✅ `nix flake check` passes **cold on both platforms** at `f46fc67` — Linux
  run 1136 flake-check 4m07s, Darwin run 796 `Check Flake` 16:57:41→16:59:39.
  The `ffmpeg_9` failure of run 1133 is gone; `ffmpeg` appears nowhere in the log.
- ✅ The `always()` tail **does** run inside a cancellation grace window (§6.3,
  Darwin run 796) — refines, but does not overturn, the run-1115 observation.
- ✅ Cachix is populated and serving: prewarm legs substituted e.g. `vscode`
  **from `krit-nixos.cachix.org`**, not upstream.
- ✅ **The self-proving step works** (run 1139 prewarm legs). Real output:
  `watch-exec streamed 0 path(s) to Cachix during the build` /
  `(0 derivation(s) were actually built; substituted paths never fire the hook)`.
  `watch.log` existed, so the `set -o pipefail` + `| tee` change works in
  production — that was the riskiest part of the change. The
  `built > 0 && streamed == 0` alarm correctly stayed **silent** at `built=0`
  (no false positive), and `pushed=0` confirms the anchored count from §3.
- ✅ `flake-check` green at `ace17ce` (2m59s) — the mpvpaper change evaluates.
- ✅ The repo owns **zero** deprecated `stdenv.isLinux`/`isDarwin` predicates
  (17 uses of `stdenv.hostPlatform.is*`). The one remaining deprecation warning
  in the eval log comes from a **flake input**, not this repo.

### 11.2 🔴 The one unproven claim: does `watch-exec` upload mid-build?

Still **UNPROVEN**, and it is the most valuable thing left, because it is the
only protection against runner death (§6.3) and the justification for the
150-minute step cap.

**The method, so nobody has to re-derive it:**

1. **Precondition first, before reading any `Pushing` line.** The hook fires only
   on derivation **completion**, and never for *substituted* paths. So the
   precondition is "derivations demonstrably **completed**" — and

   ⚠️ **`building '/nix/store/…'` lines are ANNOUNCEMENTS, not completions.**
   Counting them is not sufficient and misled this investigation once already.
   Run 1136's legs showed 5000 such lines that resolved to only ~1768 distinct
   derivations, each re-announced about three times, with a pending set that
   never shrank between passes. A satisfied-looking count can therefore describe
   a build that finished nothing at all.

   Zero builds — or builds that never demonstrably finish — means the verdict is
   **UNANSWERED, never "no"**. Both hypotheses predict zero `Pushing` lines.
2. **The discriminator is the step boundary, not the string format.**
   `Pushing /nix/store/…` **inside** the `Build <host>` block proves streaming.
   The same lines only inside the separate `Push to Cachix` step prove nothing.
3. **Timestamp spread decides it.** Lines spread across the build window are
   proof; lines clustered at its end are not.
4. Count cachix's `Pushing N paths (…)` summary header **separately** — see the
   off-by-one in §3.

**Why every attempt so far failed, so they are not repeated:**

| attempt | why it could not answer |
|---|---|
| All warm runs | 100% substituted, `building` count **0**. Hook cannot fire. |
| Run 1136 prewarm legs ×8 | Took the watch-exec branch (banner present in all 8, fallback in none) but built **0** paths; 199–443 `copying path` lines each. Null result. |
| Run 1136 flake-check | Not wrapped in watch-exec at all — it has a separate push step. Says nothing either way. |
| Darwin run 796 | Built exactly **one** derivation (`firefox-unwrapped-154.0`), which **never completed** — 2h03m of log silence, then cancelled. No completion event ⇒ no hook event. |
| Run 1136 Linux legs | Genuinely cold and building thousands of derivations, but still in flight at time of writing. **This is the live candidate.** |

**From 2026-08-19 onward this should not need forensics at all** — the
`Report Continuous Push` step (§3, layer 1) answers it on every run.

### 11.3 ⚠️ Investigating a run from a session — two API traps

- **`get_job_logs` is hard-capped at ~5000 TAIL lines — for completed jobs too.**
  Requesting `tail_lines: 60000` still returns exactly 5000. There is no
  `head`/`offset` parameter, so **the head of any large log is unreachable from a
  session**, and `original_length` is unreliable (it has come back *smaller* than
  the payload actually returned). On run 1136's legs the retrievable window was
  **31 s and 20 s — 0.73% and 0.31%** of their build steps.
- On an **in-progress** job it can also return a **frozen, non-advancing
  snapshot**: identical across repeated polls. Never read such a snapshot as the
  step's full output, and never conclude "absent" from it.
- The full-run ZIP (`get_workflow_run_logs_url` →
  `results-receiver.actions.githubusercontent.com`) is **blocked by this
  environment's egress policy (403 to CONNECT)**, so it is not a way around the
  cap. Do not retry it.
- `get_workflow_run_logs_url` returns **404 until the run reaches a terminal
  state**. Complete logs only exist after the run ends.
- When a snapshot has no `##[group]`/`##[endgroup]` markers (they scrolled out),
  attribute lines to steps using the REST **step timeline** instead: any line at
  or after the build step's `started_at`, with the next step never started, is
  inside the build step.

### 11.4 🔴 Darwin is red until Firefox 154.0 reaches `cache.nixos.org`

**Root cause, established 2026-08-19.** `flake.lock` commit `4ad758a`
(12:09:07 UTC) moved firefox **153.0.4 → 154.0**. The partition is clean:

| runs | outcome |
|---|---|
| **without** `4ad758a` (771, 783, 789) | all succeeded in **~6 min**, **0 derivations built** |
| **with** `4ad758a` (792–797) | **not one has completed** |

Four reached the identical derivation and never left it —
`jw9644qkl05mjkszcwd1vim8sdyw2s4b-firefox-unwrapped-154.0.drv` — dying at 5m19s,
20m17s, 2h04m27s, and one true 150-minute step timeout (run 794).

**This is upstream lag, not a config fault.** aarch64-darwin Firefox *is*
normally cached: `cache.nixos.org/wkl53z1p….narinfo` → **HTTP 200** for
`firefox-unwrapped-153.0.4`, and the fast runs substituted it from
`cache.nixos.org` with the wrapper coming from `krit-nixos.cachix.org`. CI has
**never** compiled darwin Firefox. Version 154.0 simply has not landed yet.

**Decision (owner, 2026-08-19): wait it out.** No config change. Both workflows
carry a weekly `0 5 * * 5` cron, so Darwin retests every Friday and on any push.
A step timeout sets `steps.build.outcome = failure`, which fires the 🔴 notifier —
**that alert is the "still not cached" signal**; its absence means recovery.

Rejected, and why, so it is not re-proposed:

- *Raise the timeout* — the compile exceeded 124 min without finishing; step cap
  150, job cap 180, hard GitHub ceiling 360. And run 794 spent **2h11m** emitting
  only `running auto-GC to free 13525108224 bytes` / `deleting garbage…`, i.e.
  the runner was **GC-thrashing under disk pressure**, so more time may not help.
- *Disable Firefox on the Mac host* — the owner declined, because the only
  host-level lever that actually works is `home-packages.enable = false`, which
  disables too much. ⚠️ Note for anyone revisiting: setting
  `krit.programs.firefox.enable = false` **alone does not work** —
  `home-packages-darwin.nix` then re-adds `pkgs.firefox` to
  `environment.systemPackages` via `lib.optional (!isProgramEnabled browserName)`.

### 11.5 🟠 A run can ignore cancellation and jam the concurrency group

Seen twice on 2026-08-19. Run 1130's `Install CA Certificates` hung unkillably
and blocked the group until its 180-minute cap. Then the 19:08:39 push cancelled
the **Darwin** run within ~40s but left `build.yml` run 1136's two Linux legs
running; run 1137 sat `pending` with **0 jobs** for 20+ minutes.

There is no in-workflow fix — `timeout-minutes` is the only real backstop, which
is one more reason the caps matter. A session cannot force-cancel either
(§10: `actions: write` → 403).

### 11.6 Still open, lower priority

- 🟠 **Why two hosts in one `nix build` was so expensive is not established.**
  Run 1115 points at evaluation and IFD rather than disk (§7). Worth an actual
  measurement — `nix build --print-build-logs` timing of the evaluation phase per
  host — before anyone theorises again.
- 🟠 **`cancel-in-progress: true` may be wrong for these workflows.** Run 1115
  shows a cancellation can discard a long build *and* skip the salvage push. For
  a workflow whose primary goal is "cache as much as possible", that is a real
  cost. The alternative (let runs finish) costs runner minutes and queue depth.
  Not yet decided — but note §6.3's 2026-08-19 data point, where the salvage push
  *did* run.
- 🟠 **Whether `tgt` / `doom` are worth pre-warming is unmeasured.** Both would
  need work to be addressable (§5): `doom` is reachable through the existing
  config tree without touching `flake.nix`, `tgt` would need a single-system
  `packages` output. Do not add either until a log shows it being *built* rather
  than substituted. A general `packages` output re-exporting flake inputs is a
  bad idea: `concord` is used via `.overrideAttrs`, so a plain re-export is a
  *different derivation* and pre-warming it would cache a path the build never
  substitutes.
- 🟠 **Wire `steps.watch_report.outputs.streamed` into the Discord notifier.**
  Today the broken-continuous-push alarm surfaces only as a `::warning::`
  annotation in the Actions UI. Deliberately deferred to keep the instrumentation
  commit small; do it once the step has been seen working on a real run.
- ⚪ **Resolved 2026-08-19, do not re-open:** per-host build timings after the
  matrix split. Run 1122 measured them — desktop **10m35s**, laptop **10m55s**,
  **17m18s wall clock for the pair**, against run 1110's 19m41s for the desktop
  alone (§7).

### 11.7 Needs the owner, not automation

Tracked in §10. Still outstanding:

- **Flake-update PRs never trigger builds.** `DeterminateSystems/update-flake-lock`
  uses the default `GITHUB_TOKEN`, and GitHub does not start workflows from
  `GITHUB_TOKEN`-created events, so those PRs land with **zero checks**. The
  permanent fix is a PAT in repository secrets — owner-only.
- **Promotion of `develop` → `main`.**
