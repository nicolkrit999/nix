# 🏗️ NixOS Infrastructure: The Binary Cache Strategy

This document explains the "Build Once, Run Everywhere" architecture used in this repository. By leveraging **Cachix** and **GitHub Actions**, we ensure that your laptop almost _never_ has to compile code from scratch, saving battery, heat, and time.

---

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
- Builds for **x86_64** (Desktop) natively.
- Builds for **AArch64** (Laptop) using QEMU emulation.

- **Why it exists:** To do the heavy lifting while you sleep. It creates the cache entries before you even wake up to update your laptop.

### 🥈 Tier 2: The Desktop (Hybrid Builder)

- **Role:** The Backup Builder / Local Factory.
- **Trigger:** Runs when you update (`nh os switch`) or manually trigger a build.
- **Configuration:**
- **Pull:** Enabled (It downloads what it can from Cachix).
- **Push:** **ENABLED**.

- **Why Push is enabled:** If you are developing a new feature locally and haven't pushed to GitHub yet, your Desktop compiles it. By enabling push, your Desktop uploads these new binaries to Cachix. If you then switch to your Laptop, it can download the binaries your Desktop just built, skipping the cloud entirely.

### 🥉 Tier 3: The Laptop (Pure Consumer)

- **Role:** The Consumer.
- **Trigger:** Runs when you update (`nh os switch`).
- **Configuration:**
- **Pull:** Enabled.
- **Push:** **DISABLED**.

- **Goal:** Zero compilation. If the Laptop starts compiling `webkit` or `gcc`, **something is wrong**. It should only ever download compressed binaries.

---

## 3. The Ideal Workflow (The "Happy Path")

To get the most out of this system, follow this lifecycle for system updates:

1. **Edit & Commit:** You make changes to your config on any device.
2. **Push:** You run `git push`.
3. **The "Coffee Break" (Wait):**

- GitHub Actions detects the push and starts two parallel jobs: `build-x86_64` and `build-aarch64`.
- It compiles your system and uploads the results to `krit-nixos.cachix.org`.
- _Duration:_ ~5-15 minutes depending on complexity.

4. **Update:**

- Once the green checkmark appears on GitHub, you run `nh os switch` on your Laptop.
- **Result:** Nix calculates the hash, sees it exists in Cachix, and downloads it. Update time: ~30 seconds.

---

## 4. Technical Implementation

### The Automation (`.github/workflows/build.yml`)

This file is the "Robot" that runs the factory.

- **Concurrency:** It cancels old builds if you push new code immediately, saving runner time.
- **The Cache Loop:** It pulls from Cachix before starting (to speed up its own build) and pushes to Cachix immediately after finishing.
- **Split Architecture:** It runs separate jobs for x86 and ARM to ensure both architectures are cached simultaneously.

### The System Logic (`modules/cachix.nix`)

This file configures your machines to talk to the warehouse.

- **Automatic Auth:** It uses `sops-nix` to securely inject your `CACHIX_AUTH_TOKEN` only on machines allowed to push (the Desktop).
- **The "Rebuild-Push" Alias:**
- It creates a shell alias `rebuild-push`.
- **Function:** Rebuilds your system _and_ uploads the result to Cachix in one go.
- **Use Case:** Use this on your Desktop when you want to share a build with your Laptop immediately without waiting for GitHub Actions.

---

## 5. Troubleshooting & FAQ

### ❓ Why does the Desktop have "Push" enabled?

To act as a local cache server. If GitHub is down, or if you are iterating rapidly on a private branch, your Desktop serves as the "Builder" for your Laptop.

### ❓ My Laptop is compiling (Cache Miss)!

If you see your laptop building `firefox`, `gcc`, or `linux-kernel`, **STOP** (Ctrl+C).

1. **You didn't wait:** GitHub Actions hasn't finished yet.
2. **You didn't push:** You made changes locally but didn't push them to the cloud.
3. **Dirty State:** You are building from a dirty git tree that doesn't match what is in the cache.

### ❓ Can I push to `develop`, merge to `main`, and push again immediately?

**Yes.** This is completely safe. GitHub Actions treats different branches as separate groups, so both builds will run in **parallel** without interfering with each other.

### ❓ What if I push to the same branch twice?

The old build will **automatically stop**.
We use `cancel-in-progress: true` in our workflow. If you push a fix 2 minutes after a previous push, the system kills the old (now obsolete) build to save resources and immediately starts the new one.
