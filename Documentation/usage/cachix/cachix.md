# 🏗️ NixOS Infrastructure & Automation Guide

## 1. The "Builder" Concept
In Nix, **any** computer that compiles code is a "Builder." We want to avoid using your personal computers as builders to save processing power and battery.

### The Hierarchy of Builders:
1.  **🥇 The Cloud (GitHub Actions):** The Primary Builder.
    * **Trigger:** Runs automatically when you `git push`.
    * **Role:** Compiles everything in the background while you sleep. Act as a `remote binaries archive`
    * **Goal:** To fill the cache *before* you update your devices.

2.  **🥈 The Desktop:** The Backup Builder.
    * **Trigger:** Runs when you update your system (`nh os switch`).
    * **Role:** If the Cloud is slow or you haven't pushed code yet, the Desktop compiles locally.
    * **Why `push = true`?** It uploads its results to the cache so your *Laptop* doesn't have to compile them later. Basically after doing `upd` or `sw` the updated binaries are uploaded to cachix, without the need to `git push`

3.  **🥉 The Laptop:** The Consumer.
    * **Trigger:** Runs when you update your system.
    * **Role:** It should **ONLY** download from the cache.
    * **Failure State:** If the cache is empty, the Laptop is forced to become a Builder, using more resources

## 2. The Ideal Workflow (Timeline)

1.  **Edit Code:** You make changes on your Desktop or Laptop.
2.  **Push:** You run `git push`.
3.  **Wait (The "Cloud Time"):** GitHub starts building. This takes ~5-15 minutes.
4.  **Update:**
    * **After 15 mins:** You run `nh os switch` on any device.
    * **Result:** It downloads the pre-built binaries from Cachix (Fast).

## 3. Frequently Asked Questions

### ❓ Why keep push enabled on the Desktop?
If you are working on a new feature but haven't pushed it to GitHub yet (e.g., testing locally), your Desktop builds it. By having `push = true`, your Desktop shares that build with your Laptop immediately, bypassing the Cloud.

### ❓ How do I fix a "Cache Miss" (Laptop building from source)?
If your laptop starts compiling heavy things (Webkit, Firefox, GCC):
1.  **Stop it** (Ctrl+C).
2.  **Check GitHub:** Did the Action finish green? ✅
3.  **Check Git:** Did you forget to push the `flake.lock` from your Desktop?
4.  **Retry:** Once the Cloud or Desktop has finished and pushed, try updating the Laptop again.

## 4. Setup Summary
* **Cachix Name:** `krit-nixos`
* **GitHub Action:** `.github/workflows/build.yml` (Triggers on push to `develop` & `main`)
* **Unfree Software:** Enabled in CI via `NIXPKGS_ALLOW_UNFREE: 1`