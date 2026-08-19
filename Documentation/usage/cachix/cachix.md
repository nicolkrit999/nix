# 🏗️ NixOS Infrastructure: The Binary Cache Strategy

This document explains the "Build Once, Run Everywhere" architecture used in this repository. By leveraging **Cachix** and **GitHub Actions**, we ensure that your laptop almost _never_ has to compile code from scratch, saving battery, heat, and time.

- Two architectures are built in the cloud today: **`x86_64-linux`** (both NixOS hosts, in `build.yml`) and **`aarch64-darwin`** (the MacBook, in `build-darwin.yml`, on a GitHub-hosted Apple-silicon runner). Both push to the same `krit-nixos` cache.
- **`aarch64-linux` is not built.** That is the architecture that would need a machine kept up to date, and a lot more Cachix space.

---

> 🔧 **Looking for how the CI workflows themselves work?** This document covers
> the strategy. For the machinery - what each job does, why the Nix settings
> differ per platform, how the three push layers work, and the incident log
> behind the current design - see
> [`../ci/build-workflows.md`](../ci/build-workflows.md).

## 1. The Core Concept: "Factory vs. Warehouse"

In a standard Nix setup, every computer acts as a **Factory**—it downloads source code and compiles it into binaries. This is slow and resource-intensive.

Our strategy transforms your devices into **Customers**:

1. **The Factory (GitHub Actions):** Compiles the code in the cloud.
2. **The Warehouse (Cachix):** Stores the finished binaries.
3. **The Customer (Your Laptop):** Simply downloads the finished product.

---

## 2. The Hierarchy of Builders

We define a strict hierarchy of trust and power to optimize resources.

### 🥇 Tier 1: The Cloud (GitHub Actions)

- **Role:** The Primary Builder.
- **Trigger:** Automatically runs on every `git push`.
- **Capabilities:**
- Builds **both** `x86_64-linux` hosts natively — `nixos-desktop` *and* `nixos-laptop`, one per runner (`build.yml`).
- Builds the **`aarch64-darwin`** Mac natively on a `macos-15` runner (`build-darwin.yml`).

- **Why it exists:** To do the heavy lifting while you sleep. It creates the cache entries before you even wake up to update your laptop.

### 🥈 Tier 2: The Desktop (Hybrid Builder)

- **Role:** The Backup Builder / Local Factory.
- **Trigger:** Runs when you update (`nh os switch`) or manually trigger a build.
- **Configuration:**
- **Pull:** Enabled (It downloads what it can from Cachix).
- **Push:** **ENABLED**.

- **Why Push is enabled:** If you are developing a new feature locally and haven't pushed to GitHub yet, your Desktop compiles it. By enabling push, your Desktop uploads these new binaries to Cachix. If you then switch to your Laptop, it can download the binaries your Desktop just built, skipping the cloud entirely.

### 🥉 Tier 3: The Laptop

- **Role:** Mostly a consumer, but it *can* push.
- **Trigger:** Runs when you update (`nh os switch`).
- **Configuration:**
- **Pull:** Enabled.
- **Push:** **ENABLED** — `hosts/nixos-laptop/default.nix` sets `cachix.push = true` with the same `/run/secrets/cachix-push-token` as the Desktop.

- **Goal:** Still zero compilation in normal use. If the Laptop starts compiling `webkit` or `gcc`, **something is wrong** — but if it does build something, that result is uploaded rather than thrown away.

### 🍎 Tier 3b: The MacBook (`Krits-MacBook-Pro`)

- **Role:** Consumer, with its own cloud builder.
- **Configuration:** Pull **and** push enabled, same token (`hosts/Krits-MacBook-Pro/default.nix`).
- **Its factory** is `build-darwin.yml`, not `build.yml` — a separate workflow on a `macos-15` runner. `build.yml` never builds anything for macOS.

### 📦 A second warehouse: `attic`

All three hosts also push to a self-hosted **attic** cache on the NAS
(`myconfig.attic`, `attic-push` alias). Cachix is the public/offsite warehouse;
attic is the local one. This document only covers Cachix.

---

## 3. The Ideal Workflow (The "Happy Path")

To get the most out of this system, follow this lifecycle for system updates:

1. **Edit & Commit:** You make changes to your config on any device.
2. **Push:** You run `git push`.
3. **The "Coffee Break" (Wait):**

- GitHub Actions detects the push and starts the compilation`.
- It compiles your system and uploads the results to `krit-nixos.cachix.org`.
- _Duration:_ ~15-20 minutes for a **warm** `x86_64-linux` run (run 1110: 12m44s of building, ~20 minutes end to end). A **cold** run — anything that changes `flake.lock`, since the store-cache key includes its hash — is far slower, and the caps are deliberately generous (270-minute build step, 350-minute job).

4. **Update:**

- Once the green checkmark appears on GitHub, you run `nh os switch` on your Laptop.
- **Result:** Nix calculates the hash, sees it exists in Cachix, and downloads it. Update time: ~30 seconds.

---

## 4. Technical Implementation

### The Automation (`.github/workflows/build.yml`)

This file is the "Robot" that runs the factory.

- **Trigger:** `push` only on **`develop`** and **`main`**, plus **any pull request**, a weekly schedule, and manual dispatch. Pushing a feature branch with no PR open does *not* start a build.
- **Concurrency:** It cancels older runs of the same workflow on the same ref. ⚠️ This is a genuine trade-off, not a free saving — a cancelled run can lose a long build *and* skip its salvage push. Avoid pushing again while a build you care about is in flight.
- **The Cache Loop:** It pulls from Cachix before starting, and pushes **continuously during the build** via `cachix watch-exec`, not only at the end. It also pushes when the build *fails*, so a broken package never costs you everything else.
- **Split by host, not by architecture:** `build.yml` has no ARM job — every job runs on `ubuntu-latest`. Its build matrix splits over the two **x86_64 hosts** (`nixos-desktop`, `nixos-laptop`), one per runner. macOS is a separate workflow entirely.

> 📖 For the full mechanics — the three push layers, why the Nix settings differ per platform, and the incident log behind the current design — see [`../ci/build-workflows.md`](../ci/build-workflows.md).

### The System Logic (`cachix.nix`)

This file configures your machines to talk to the warehouse.

- **Automatic Auth:** `sops-nix` injects the token at `/run/secrets/cachix-push-token`. All three hosts currently enable push and reference it.
- **Pushing happens automatically on switch.** The rebuild aliases are wrapped (`wrapCaches` in `modules/common/programs/shells/shell-aliases.nix`), so a normal `sw`/switch already pipes `nix path-info -r /run/current-system` into both `attic push` and `cachix push`. Each is suffixed `|| true`, so a cache being unreachable never fails your rebuild.
- **The manual alias is `cachix-push`** (and `attic-push` for the NAS). There is no `rebuild-push` alias.
- **Use Case:** run `cachix-push` when you want to share the *current* system closure immediately without waiting for GitHub Actions.

---

## 5. Troubleshooting & FAQ

### ❓ Why do the machines have "Push" enabled?

To act as a local cache server. If GitHub is down, or if you are iterating rapidly on a private branch, your Desktop serves as the "Builder" for your Laptop.

### ❓ My Laptop is compiling (Cache Miss)!

If you see your laptop building `firefox`, `gcc`, or `linux-kernel`, **STOP** (Ctrl+C).

1. **You didn't wait:** GitHub Actions hasn't finished yet.
2. **You didn't push:** You made changes locally but didn't push them to the cloud.
3. **Dirty State:** You are building from a dirty git tree that doesn't match what is in the cache.

### ❓ Can I push to `develop`, merge to `main`, and push again immediately?

**Yes.** This is completely safe. GitHub Actions treats different branches as separate groups, so both builds will run in **parallel** without interfering with each other.

### ❓ What if I push to the same branch twice?

Usually, yes — we use `cancel-in-progress: true`, so pushing a fix kills the now-obsolete build and starts the new one.

⚠️ **Two caveats worth knowing:**

1. It is not instantaneous or perfectly ordered. An older in-progress run has been observed continuing while newer runs in the same group were cancelled and the newest sat `pending` for 20+ minutes. GitHub's queue can be slow — be patient before assuming something is broken.
2. **Cancelling is not free.** A cancelled run can lose everything it had left to do, including its salvage push to Cachix (observed in run 1115). What it already built is usually safe, because `watch-exec` uploads paths as they are produced — but if a build matters, let it finish.
