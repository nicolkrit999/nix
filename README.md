# ❄️ Personal NixOS Config

> ⚠️ Screenshots may be outdated. Documentation is updated incrementally.

![hyprland-showcase](./Documentation/showcase-screenshots/hyprland-showcase.png)

---

## ✨ Features

→ [Full feature descriptions](./Documentation/features.md)

- Adaptive host support via denix (per-host modules and constants)
- Host-specific home-manager modules (`/users` + `/modules`) and manual-import templates (`/templates`)
- Hybrid declarative + non-declarative modules (shells, caelestia, noctalia)
- Theming: base16 + optional Catppuccin via stylix
- Host-specific wallpapers tied to monitor list
- Multiple desktop environments: Hyprland with waybar, Hyprland with caelestia, Hyprland with noctalia, niri with noctalia, MangoWM with mangowc, KDE, GNOME, Cosmic
- NixOS specializations: guest (ephemeral RAM home), safe-mode (IceWM recovery shell), deep-focus (distraction-free workspaces), secure-travel (hardened, kill-switch VPN)
- flakes & Home Manager integration
- Multiple shells (bash, zsh, fish)
- Optional BTRFS snapshots with per-host retention policy
- SOPS-nix secret management
- Impermanence (root wiped on reboot, `/persist` for state)
- Cachix binary cache support
- Multi-architecture: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin` ⚠️ best-effort — no physical aarch64-linux or aarch64-darwin hardware available for testing

---

## 🚀 Installation

### Common Steps (both methods)

1. Boot a **NixOS Minimal ISO** from a USB stick (UEFI, Secure Boot off).
2. Connect to the internet (`sudo nmtui` for WiFi).
3. Download the config:
   ```bash
   nix-shell -p git
   git clone https://github.com/nicolkrit999/nix.git
   cd ~/nix
   ```
4. Change `homeManagerUser` in `flake.nix` to your chosen username.
5. Copy a host template, configure the minimal variables, such as `user`, `homeManagerSystem`, then proceed with your chosen method below.

### Choose Your Installation Method

| Method | Guide |
|--------|-------|
| **Disko** (automated partitioning — recommended for fresh installs) | [Installation with disko](./Documentation/installation/disko.md) |
| &nbsp;&nbsp;↳ Option A: No encryption | [disko.md — Option A](./Documentation/installation/disko.md#option-a-standard-no-encryption) |
| &nbsp;&nbsp;↳ Option B: LUKS + TPM 2.0 | [disko.md — Option B](./Documentation/installation/disko.md#option-b-secure-luks--tpm-20) |
| **Manual** (dual boot or custom partitioning) | [Manual installation](./Documentation/installation/manual.md) |
| &nbsp;&nbsp;↳ Option A: No encryption | [manual.md — Option A](./Documentation/installation/manual.md#option-a-btrfs-no-encryption) |
| &nbsp;&nbsp;↳ Option B: LUKS + encryption | [manual.md — Option B](./Documentation/installation/manual.md#option-b-btrfs--luks-encryption) |

---

## 🔄 Daily Usage

→ [Daily usage guide](./Documentation/daily-usage.md)

| Alias | Description |
|-------|-------------|
| `sw` | Rebuild everything |
| `upd` | Update flake inputs and rebuild |

---

## ❓ Troubleshooting

→ [Troubleshooting guides](./Documentation/troubleshooting/)

**Quick reference:**

- `path '.../hardware-configuration.nix' does not exist` → `git add -f hosts/<hostname>/hardware-configuration.nix`
- `permission denied` on `flake.lock` → `sudo chown -R $USER:users ~/nix`
- `returned non-zero exit status 4` → usually a service restart failure after a successful build; try rebuilding again
- Weird keyboard layout during install → `loadkeys <layout>` to fix temporarily
- Caelestia/noctalia font issues → install the font in `configuration.nix` or `home-packages.nix`

---

## 📚 Other Resources

| Resource | Link |
|----------|------|
| Showcase | [showcase.md](./Documentation/showcase.md) |
| Features (in depth) | [features.md](./Documentation/features.md) |
| Denix possibilities | [possibilities.md](./Documentation/usage/denix/possibilities.md) |
| Denix official docs | [denix-official-documentation.pdf](./Documentation/usage/denix/denix-official-documentation.pdf) |
| Impermanence guide | [impermanence.md](./Documentation/usage/impermanence/impermanence.md) |
| SOPS guide | [sops-guide.md](./Documentation/usage/sops/sops-guide.md) |
| Cachix guide | [cachix.md](./Documentation/usage/cachix/cachix.md) |
| Tmux guide | [tmux-guide.md](./Documentation/usage/tmux/tmux-guide.md) |
| Emergency recovery (GRUB) | [emergency-recovery-gnu-grub.md](./Documentation/troubleshooting/emergency-recovery-gnu-grub.md) |
| Emergency recovery (script) | [recover.sh](./Documentation/troubleshooting/recover.sh) |
| Notes & project origin | [notes.md](./Documentation/notes.md) |
