# 🛠️ Development &amp; Customization Guide

This guide explains how to extend and modify the configuration. Follow these standard procedures to ensure consistency across all hosts.

## 🖥️ Adding a Desktop Environment (DE)

To add a new desktop environment (in this example cinnamon) to the flake:

1. **Define the Variable:**
   Add the enable flag to `hosts//variables.nix` for _every_ host (set to `false` by default, `true` where needed).

```nix
# variables.nix
cinnamon = false;

```

2. **Create the System Module:**
   Create a file in `nixos/modules/cinnamon.nix`. Use `lib.mkIf` to ensure it only loads when the variable is true. For example:

```nix
{ pkgs, lib, vars, ... }: {
  services.xserver.desktopManager.cinnamon.enable = lib.mkIf (vars.cinnamon or false) true;

  # Exclude default packages if necessary
  environment.cinnamon.excludePackages = [  ];
}
```

1. **Create the Home Manager Module:**

- Create a folder: `home-manager/modules/cinnamon/`
- Create `home-manager/modules/cinnamon/default.nix` inside it.
- Import the general folder in `home-manager/core.nix`

1. **Populate the Home Manager Module:**
   In `default.nix`, import and create your main logic files (e.g., `cinnamon-main.nix`, `cinnamon-binds.nix`).

- `cinnamon-main.nix` to provide the best experience should do at least these jobs:
  - Traverse the monitors and the wallpapers list and apply the wallpapers
  - Make theming dynamic based and the combination of base16Theme + polarity and a conditional with capputtin if desired

---

## 🎨 Adding a Catppuccin Module

To add Catppuccin theming support for a specific program:

- First of all verify it exist as possible option

1. **Disable Stylix Auto-Theming:**
   Open `home-manager/modules/stylix.nix` and add the program to the `targets` list to prevent conflicts.

```nix
stylix.targets.program-name.enable = !vars.catppuccin;

```

2. **Create the Conditional Logic:**
   In the program's module file (e.g., `programs/program-name.nix`), use logic to switch between Catppuccin and the standard Base16 theme.

```nix
programs.program-name = {
  enable = true;
  # If Catppuccin is enabled, use its specific setting
  theme = if vars.catppuccin then "catppuccin-${vars.catppuccinFlavor}"
          # Fallback to the generic Base16 theme
          else "base16-${vars.base16Theme}";
};

```

---

## 🏠 Adding Host-Specific Home Modules

Use this when you need complex Home Manager modules that apply _only_ to one specific machine.

1. **Create the Default Import:**
   Create `hosts/host-modules/default.nix`. This file acts as the entry point.

```nix
{ ... }: {
  imports = [
    ./my-custom-module.nix
    ./another-module.nix
  ];
}
```

3. **Warning on System-Level Configs:**
   Home Manager cannot handle system-level services (like hardware drives, docker daemon, or bootloaders). If your module needs these, it must be imported in `configuration.nix` instead.
   **Example (`hosts/configuration.nix`):**

```nix
imports = [
  ./host-modules/my-system-service.nix
];
```

---

## ➕ Adding New Variables

You have two ways to introduce new configuration variables.

### Option A: Host Variables (Standard)

Best for simple flags (true/false) or strings (usernames, themes) that every host needs.

1. Add the variable to `hosts//variables.nix`.
2. **Usage:** In any module, simply add `vars` to the arguments and reference it.

```nix
{ pkgs, vars, ... }: {
  someOption = vars.myNewVariable;
}
```

### Option B: Module Variables (Advanced)

Best for complex, per-host logic (e.g., defining monitor layouts or specific hardware IDs) where you want "Safe Defaults".

1. Define the logic in `hosts//modules.nix`.
2. **Usage:** In your code, use `vars` but provide a fallback in case the variable is missing.

```nix
# If 'vars.mySpecialVar' doesn't exist, default to "default-value"
someOption = vars.mySpecialVar or "default-value";
```

---

## 📦 Adding Global Home Manager Modules

To add a generic Home Manager module (e.g., a new CLI tool config) that applies to **ALL** hosts:

1. **Create the File:**
   Add your file to `home-manager/modules/` (e.g., `home-manager/modules/git.nix`).
2. **Import It:**
   Open `home-manager/modules/default.nix` and add it to the `imports` list.

```nix
imports = [
];
```

1. **Effect:** This configuration will now be active on every machine you build.

---

## ⚙️ Adding Global System Modules

To add a global system configuration (e.g., generic security settings, networking rules) that applies to **ALL** hosts:

1. **Create the File:**
   Add your file to `nixos/modules/` (e.g., `nixos/modules/security.nix`).
2. **Import It:**
   Open `nixos/modules/core.nix` and add it to the imports.
3. **Effect:**

- This is **Global**: It applies to every host.
- **Power:** System modules run as `root` and control the OS state. They are more powerful than Home Manager modules.

---

### 📸 Snapshot Management Guide

This configuration uses **Snapper** with **Btrfs** for system and home backups. It includes automatic timeline snapshots and manual controls.

#### 📂 File Locations & Structure

To prevent infinite recursion (snapshotting snapshots), the structure is split:

- **Root Snapshots:** Stored in `/.snapshots` (Subvolume ID depends on setup).
- **Home Snapshots:** Stored in `/home/.snapshots`.
- _Note:_ `/home/.snapshots` is a **dedicated subvolume**, separate from `/home`.

#### 🛠️ GUI Tools

- **Snapper GUI:** A graphical interface to browse and compare snapshots.

- **Btrfs Assistant:** Advanced tool for managing subvolumes and Snapper configs.

#### ⌨️ Custom CLI Commands (Interactive)

These commands are defined in your shell configuration (`zsh.nix`) for ease of use.

| Command                | Description                                                                                         | Interactive? |
| ---------------------- | --------------------------------------------------------------------------------------------------- | ------------ |
| **`snap-create-home`** | Creates a snapshot of `/home`. Asks for a description and whether to **Lock** it (keep forever).    | ✅ Yes       |
| **`snap-create-root`** | Creates a snapshot of `/` (Root). Asks for a description and whether to **Lock** it.                | ✅ Yes       |
| **`snap-lock`**        | Locks an existing snapshot so it is **never deleted**. Asks for Config (Home/Root) and Snapshot ID. | ✅ Yes       |
| **`snap-unlock`**      | Unlocks a snapshot, enabling **auto-deletion** (timeline cleanup). Asks for Config and ID.          | ✅ Yes       |
| **`snap-list-home`**   | Quickly lists all snapshots for `/home`.                                                            | ❌ No        |
| **`snap-list-root`**   | Quickly lists all snapshots for `/` (Root).                                                         | ❌ No        |

#### 🔒 Locking vs. Unlocking

- **LOCKED (`Cleanup` column is empty):** Safe. Snapper will **never** delete this. Use this for critical states (e.g., "Before Driver Update").
- **UNLOCKED (`Cleanup: timeline`):** Temporary. Snapper will automatically delete this when it gets too old, based on the retention policy defined in `snapshots.nix`.

---
