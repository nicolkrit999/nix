---
name: creating-nix-modules
description: Use this skill when adding or modifying nix configuration that introduces new functionality: denix modules, enabling programs/services, host constants, theming, home-manager config. Packages default to the unstable package set (pkgs.X); the stable set (pkgsStable) is used only when the prompt explicitly says so. Trigger phrases include 'add a module', 'enable X on host Y', 'install/integrate package Z', 'configure <service> in nix', 'add this to my nixos config', 'set up <program> via home-manager'. Drives research, author, borg-exclude, lint and verify across nix-package-researcher, nix-config-architect, nix-syntax-linter and nix-checker. Does NOT cover diagnosing an existing build failure (use debugging-nix-failures) or pure lookups with no authoring (dispatch nix-package-researcher directly).
---

# Creating Nix Modules

The repo CLAUDE.md mandates delegating authoring, linting, and verification
to agents - never do this work directly in the main loop. The orchestrator
(this chat) dispatches each stage and loops; agents cannot call each other.

## Step R - RESOURCE CHECK (first, main loop, before any heavy dispatch)

Run `bash .claude/skills/_shared/resource-check.sh` and apply its output as
described in `.claude/skills/_shared/resource-check.md` (hardware-based, never
hostname-based): cap parallel heavy agents at `max_parallel_agents`, pass
`nix_flags` into every build brief, and use `--parallel` tests only when
`run_tests_parallel=yes`. If the user reports lag, drop a tier first.

## The pipeline

**1. RESEARCH - dispatch `nix-package-researcher`** to confirm exact
attribute paths, option names, and channel availability before any authoring
begins. Training data lags nixpkgs, so don't trust remembered attribute names.
Research defaults to `nixos-unstable`; only if the user says in the prompt that
the package must be stable, also have the researcher check the stable channel
for that package (existence, version). Skip this step only if the task genuinely needs no lookup (e.g. purely
structural change with no new packages/options).

**2. AUTHOR - dispatch `nix-config-architect`** with the task plus the
researcher's findings. It follows repo patterns: denix `delib.module`/`host`
conventions, the 3-way common/nixos/darwin split, the constants system, and
must never bump `stateVersion`.
- **If this introduces a pin/overlay/`mkForce`/similar tied to a current
  upstream limitation** (missing hardware support, an open upstream issue,
  a package not yet released), that's a memory event, not just code. Before
  writing a new memory file for it, search
  `/home/krit/.claude/projects/-home-krit-nix/memory/` for an existing entry
  about this same issue - update it additively (new date, refreshed status)
  rather than duplicating it. Only create and index a new file when nothing
  already covers it. Comments in the code itself stay terse (a one-line
  pointer at most) - the full story lives in memory.
- **Channel rule:** use `pkgs.X` (unstable) by default. ONLY if the user's
  prompt says a module/package must be stable: have the architect take
  `pkgsStable` as an OUTER module argument (`{ delib, pkgs, pkgsStable, ... }:`,
  not inside `ifEnabled`, which only receives `cfg`/`myconfig`), use
  `pkgsStable.X` for just that package (works in `nixos.*`, `darwin.*`,
  `home.*`) with a one-line why-pinned comment, and record the pin and drop
  condition per `Documentation/usage/denix/pkgs-stable.md`. Pin only
  self-contained leaf packages (never libraries, drivers or desktop
  frameworks; see its risks section). Treat it as a memory event.
- **Default placement rule:** before authoring, dispatch `nix-compat-checker`
  to determine whether what's being implemented is compatible with
  nix-darwin - do not decide this yourself or leave it to the architect to
  guess. If it is NOT darwin-compatible, it goes in `modules/nixos/`
  (NixOS-only) - never `modules/common/`. If it IS darwin-compatible, it
  goes in `modules/common/` so both platforms get it. Feed
  `nix-compat-checker`'s judgment into the architect's task. This default
  only applies when the user hasn't specified otherwise in their prompt -
  an explicit user instruction on placement always wins.

**3. BORG EXCLUDES - dispatch `nix-package-researcher`, then
`nix-config-architect`.** Run this once authoring is done and the module's
final shape is known, but before lint/verify so those stages cover the borg
edits too. Skip it only when the change adds no program/service that writes
to `$HOME` (pure option/theming tweaks).
- **Research (`nix-package-researcher`, lookup only, no edits):** for every
  program/service the change installs or enables, find which directories and
  files it creates in the home folder (upstream docs, XDG usage, the package
  source or wrapper, and `~/.config`, `~/.cache`, `~/.local/share`, dotdirs
  in `~`). Return only paths that are **large and regenerable** - caches,
  downloaded models/runtimes/engines, browser-style profiles, Electron
  `Cache`/`Code Cache`/`GPUCache`/`IndexedDB`/`Local Storage`, VM images,
  package stores, logs - because those only cost NAS space and time. Never
  propose config, credentials, history or user data: those stay backed up.
  Also say which returned paths an existing broader pattern already covers
  (e.g. `/home/*/.cache`, `/home/*/.local/state`; on Darwin `${home}/Library`
  and `${home}/.local` are excluded wholesale) so no redundant line is added.
- **Apply (`nix-config-architect`):** add each surviving path to the exclude
  lists, by where the module was placed in step 2:
  - `modules/common/` (darwin-compatible): **all three** files -
    `users/krit/nixos/services/nas/borg-backup/borg-backup-desktop.nix`,
    `.../borg-backup-laptop.nix` and
    `users/krit/darwin/services/nas/borg-backup/borg-backup-Krits-MacBook-Pro.nix`.
  - `modules/nixos/` (NixOS-only): **desktop and laptop** files, not Darwin.
  - `modules/darwin/` (Darwin-only): the Darwin file only.
  - **Host-independent:** apply it to every file the placement implies, even
    when the module is enabled on only some hosts. If another host enables the
    module later, its exclude must already be in place and nobody should have
    to remember it. Never limit the edit to the host that enables the module.
  - Path style: NixOS lists use `"/home/*/<path>"`; the Darwin list uses
    `"${home}/<path>"` and only needs entries outside `~/Library` and `~/.local`.
  - **Alphabetical order:** each list is grouped by commented category
    (secrets, browsers, developer tools, ...). Put the new entry in the
    fitting group and keep that group sorted alphabetically (case-insensitive,
    byte order of the quoted string); a trailing `# why` comment is optional
    and short. If a group is found unsorted, sort it in the same edit - borg
    excludes are order-independent, so this is safe. Keep the desktop and
    laptop lists identical (they differ only in schedule/unit settings).
- The affected test (`test-borg-backup-config`) is picked up by step 5 because
  the borg files changed.

**3b. PIN REGISTRATION - dispatch `nix-config-architect`.** Run after step 3,
before lint. Scan what steps 2-3 wrote (new files and edited hunks) for upstream
fetches: `fetchFromGitHub`, `fetchurl`, `fetchCrx`, `fetchzip`, `fetchgit`,
`fetchTarball`, flatpak bundles, AppImage entries, Raycast extension hashes,
wheels, and any `hash`/`sha256`/`npmDepsHash`/`vendorHash`/`cargoHash` literal
tied to a version, tag or rev. Skip when there are none.
- **Classify each one.** It is a *workaround* if it is an overlay, `mkForce`,
  patch, or pin that exists because of a current upstream limitation (it already
  gets a memory entry per step 2 and goes in the EXCLUDED table). It is
  *routine* if it is pinned only because Nix needs a fixed version and hash.
- **Register it** in `.claude/skills/bumping-nix-pins/references/inventory.md`:
  routine -> INCLUDED under the fitting batch (or a new batch letter), with file,
  what is pinned, upstream source, every hash that must change, and couplings
  (duplicated host files, version comments, companion pins). Workaround ->
  EXCLUDED table with a one-line reason and the memory file name. If the fetch
  type is new, add a short recipe to `references/recipes.md` too.
- **Same-edit rule:** the inventory edit belongs to the same change as the module,
  so the next `bumping-nix-pins` run never needs discovery. Mention the edit in
  the final report. When unsure whether a pin is routine or a workaround, ask
  the user rather than guessing; wrongly listing a workaround as routine would let
  the bump skill revert it.

**4. LINT - dispatch `nix-syntax-linter`** to parse/format-check the new code,
check for denix anti-patterns, and flag any comment that violates this repo's
Comment Discipline (non-terse, narrates a diagnosis/fix, or restates trivial
code). It is read-only - findings go back to `nix-config-architect` to fix,
not applied by the linter itself.

**5. VERIFY - dispatch `nix-checker`** to run flake check, the relevant
per-host dry-builds, and the tests suite.
- On failure, switch to the `debugging-nix-failures` loop: dispatch
  `nix-debugger` with the verbatim error, then re-check via `nix-checker`.

**6. Loop 4 -> 5** until the linter reports no findings AND nix-checker is
fully green.

**Safeguard:** after ~4 rounds without convergence, stop and report the
remaining issues to the user instead of continuing indefinitely.

**7. DOCUMENT - dispatch `nix-config-architect`** to add an entry for each
new module to `Documentation/usage/denix/possibilities.md`, under the
matching section (Common Modules, NixOS-Only Modules, or Darwin-Only
Modules - and the correct subsection, e.g. Programs/Services/System) based on
where the module was placed. Follow the file's existing bullet format:
module path in backticks, a one/two-sentence description, and a
`**Warning:**` line only when disabling or misusing the module has real
consequences (mirroring the style already used throughout that file). Skip
this step for changes to an already-documented existing module - it only
applies to genuinely new modules. `nix-config-architect` is used here (not
another agent) because it authored the module and already holds its purpose
and placement in context; no other agent in this pipeline touches
documentation.
- **Exclusion - anything under `users/`:** modules created anywhere inside
  the repo-root `users/` directory are opinionated, personal config - not
  general-purpose modules useful to everybody - and must NOT get a
  `possibilities.md` entry. Skip step 7 entirely for any module whose path
  starts with `users/`.

## Exit condition

Linter clean + `nix-checker` green + borg excludes applied to every file the
placement implies (or an explicit "nothing worth excluding") + `possibilities.md`
updated for any new modules + any new fetched pin registered in the
`bumping-nix-pins` inventory (or an explicit "no pins"). Report to the user exactly what was created or
modified, on which host(s), which borg exclude paths were added to which files,
and confirm the documentation entry was added.

## Out of scope

- Diagnosing an already-failing build/eval with no new authoring involved -
  that's `debugging-nix-failures`.
- A pure attribute/option lookup with nothing to author - dispatch
  `nix-package-researcher` directly instead of running this pipeline.
