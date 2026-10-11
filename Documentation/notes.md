# Notes

## On the Declarative Aspects

Some modules are better customized using their own official methods rather than Nix syntax.

These modules use a dedicated `*.nix` file that defines basic logic and/or sources an external directory or file. This enables two scenarios:

1. **With a custom setup** (stowed from another repo, or configured directly at the original path):
   - Hybrid environment — everything defined in both the `*.nix` file and the original file/directory applies.

2. **Without a custom setup** (original location is empty or default):
   - Only the `*.nix` behavior applies, effectively a no-op on the non-Nix side.

Currently applies to:

| Tool | Nix reference | Original reference |
|------|---------------|--------------------|
| Shells (zsh, bash, fish) | `modules/common/programs/shells/{zsh,bash,fish}.nix` | `~/.zshrc_custom`, `.bashrc_custom`, `.custom.fish` |
| Caelestia | `modules/nixos/programs/shells/caelestia-main.nix` | `~/.config/caelestia/shell.json` |
| Noctalia | `modules/nixos/programs/shells/noctalia-main.nix` | `~/.config/noctalia/config.json` |

---

## Project Origin and Customization

This NixOS configuration began as a local copy and adaptation of the excellent work by **Andrey0189**: [nix-config-reborn](https://github.com/Andrey0189/nix-config-reborn).

While that repository laid the foundation, this setup has been **heavily customized** and expanded over time. Key changes include:

- **Heavily improved host variables**: many more aspects configurable per host.
- **Multiple Desktop Environments**: Hyprland (with waybar, caelestia, noctalia), Mango, niri, KDE, GNOME, Cosmic (XFCE only for the guest specialization).
- **Ephemeral Guest User**: secure, non-persistent account with automatic RAM-based home wipe on reboot.
- **Theming Overhaul**: base16 colorscheme + Catppuccin via `stylix`.
- **Hybrid Declarative Aspects**: declarative config coexisting with official non-Nix customization methods.
- **Flake Configuration**: enhanced to support many per-host variables.
- **Common modules**: general home-manager modules shared across hosts.
- **Cachix support**: pre-built binary cache.
- **Multi-architecture support**: x86_64, aarch64-linux, aarch64-darwin (macOS).

The `LICENCE.txt` is copied from the original repo and respects the GPLv3 terms.

For issues: githubgitlabmain.hu5b7@passfwd.com
