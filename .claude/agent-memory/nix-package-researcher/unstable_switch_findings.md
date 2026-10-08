---
name: unstable_switch_research_26_05_to_unstable
description: Research findings for switching nix-config from stable 26.05 to unstable 26.11; channels, flake lock strategy, ecosystem compat
metadata:
  type: reference
---

# Unstable Channel Switch: Research Findings

**Date:** 2026-10-08  
**Repo:** /home/krit/nix (denix-based, flake-driven)  
**Scope:** Switching nixpkgs from nixos-26.05 to nixos-unstable (26.11)

## Critical Facts Verified

### Channels & Versions
- **nixos-unstable** is currently **26.11** (checked via raw.githubusercontent.com/nixos/nixpkgs/nixos-unstable/lib/.version)
- **nixos-26.05** is current stable; will become obsolete once 26.11 stabilizes
- **nixos-25.11** is the previous stable (still supported, used as fallback for nix-darwin)

### Flake Semantics: nix-channel is Irrelevant
- **This repo uses flakes** (denix framework auto-discovers modules; flake.nix defines inputs)
- **nix-channel commands** are imperative, stateful, only affect `/nix/defexpr/channels/` and legacy workflows
- **Flakes are declarative**: flake.nix declares intent, flake.lock records exact commits
- **User suggestion to run `sudo nix-channel --add ...` is a no-op** for this setup
- **Correct approach**: edit flake.nix URLs, run `nix flake lock --update-input <name>`, rebuild

### Branch Availability (as of 2026-10-08)
| Component | Branch | Status | Notes |
|-----------|--------|--------|-------|
| nixpkgs | nixos-unstable | ✅ Active | Current: 26.11 |
| nix-darwin | nix-darwin-25.11 | ✅ Latest stable | No 26.11 or unstable branch exists; master is moving target |
| home-manager | release-26.05 | ✅ Explicit support for unstable nixpkgs | release-26.11 branch does not exist; master is risky |
| stylix | release-26.05 | ✅ Assume same as home-manager | Repo check failed; pattern matches home-manager/catppuccin |
| catppuccin | release-26.05 | ✅ Verified via API | No 26.11 branch; main branch exists but is unstable |

### Flake Lock Strategy
- **`nix flake lock --update-input nixpkgs`** fetches latest unstable commit
- **`nix flake lock --update-input nix-darwin`** updates to latest 25.11 (no 26.11 yet)
- **All other inputs use `follows`**: they inherit the nixpkgs change automatically
- **Do NOT run bare `nix flake update`** - re-evaluates all inputs independently, can cause breakage

### Nix Package Management
- **nix.package = pkgs.nix** in /home/krit/nix/modules/nixos/toplevel/nix-nixos.nix
- **Nix itself will auto-upgrade** when nixpkgs switches from 26.05 to unstable
- **`nix upgrade-nix` is not needed** - only updates user profile, not system Nix
- **Safe to run**, but redundant for this change

### Rollback Semantics
- **Each rebuild creates a system generation** in /nix/var/nix/profiles/system-profiles/
- **Boot loader (GRUB/systemd-boot) lists all generations** as boot options
- **Can rollback from boot menu** even if system doesn't boot
- **`nixos-rebuild switch --rollback`** activates previous generation without rebuilding
- **No preemptive rollback needed** - it's a fallback mechanism

### Risk Factors & Mitigations
| Risk | Severity | Mitigation |
|------|----------|-----------|
| Breaking changes mid-cycle | High | Migrate on develop branch; user has V7.2.1-pre-unstable-channel-switch backup release |
| Hydra channel blocking | Medium | Unstable is less stable; check hydra.nixos.org/job/nixos/unstable/tested/latest if rebuild fails |
| No release notes | Low | Unstable changes continuously; major issues posted to discourse.nixos.org |
| Longer evaluations | Low | Unstable has more packages; negligible impact |
| Ecosystem lag (HM, stylix, catppuccin) | Medium | Keep release-26.05 initially; they explicitly test this scenario; upgrade to 26.11 branches when available |

## Flake.nix Changes Required

### Input URL Changes
| Input | Line | Current | Target | Rationale |
|-------|------|---------|--------|-----------|
| nixpkgs | 114 | nixos-26.05 | nixos-unstable | Main migration |
| nix-darwin | 133 | nix-darwin-26.05 | nix-darwin-25.11 | No 26.11 yet; master is risky |
| home-manager | 145 | release-26.05 | KEEP | Supports unstable; 26.11 branch doesn't exist |
| stylix | 150 | release-26.05 | KEEP | Same as HM |
| catppuccin | 172 | release-26.05 | KEEP | Same as HM |

### Additional Inputs
- **nixpkgs-unstable** (line 115): Currently unused in code; can be removed or kept for future reference
- **claude-desktop** (line 123): Explicitly follows `nixpkgs-unstable`; will auto-update with unstable nixpkgs change

## Ecosystem Compatibility Note

When nixpkgs switches to unstable:
1. home-manager/release-26.05 is tested against unstable nixpkgs by its maintainers
2. If it breaks: look for missing options (nix-debugger role) or incompatible assumptions
3. **Fallback if Tier 1 breaks**: use home-manager/master or pin specific modules to stable nixpkgs via overlay (Tier 2 in detailed findings)

## No Stable Pin Needed Yet

User proposed `pkgsStable = import nixpkgs-stable { ... }` to pin specific packages.  
**Assessment**: Useful only if specific packages are broken in unstable.  
**Current status**: No such packages identified.  
**Recommendation**: Defer until a specific breakage is found; then add with comment.

## State Versions Are FROZEN

- system.stateVersion and home.stateVersion are locked by design (backward-compat contracts)
- **DO NOT CHANGE THEM** during channel switch
- Confirmed in CLAUDE.md: "stateVersion is NEVER bumped"
