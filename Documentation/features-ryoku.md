# The Ryoku specialization

`specializations.ryoku` adds a boot entry (tag `ryoku`) that runs the upstream [Ryoku](https://github.com/Ryoku-dev/Ryoku-on-NixOS) desktop (its own Hyprland and niri sessions, shell, Hub settings app and launcher) as a dedicated account `<user>-ryoku`. This page explains how our setup is built, what is declared in Nix, what Ryoku owns and what is deliberately left to its GUI. For the option reference see [`possibilities.md`](usage/denix/possibilities.md); for open risks, the post-boot checklist and the removal recipe see [`ryoku-specialization.md`](usage/gotchas/ryoku-specialization.md).

> **Not a toggle like noctalia or caelestia.** Those are shells you switch on or off inside your normal session (a conditional enable/disable of a module for the same user). Ryoku is a complete NixOS **specialization with its own user**: a separate boot entry, a separate account and home, and its own set of forced-off modules. Selecting it at the boot menu gives you a different system generation where the base user does not exist; nothing in your normal session changes, and nothing Ryoku does is visible from it.

- [How it is organised](#how-it-is-organised)
- [The generic module](#the-generic-module)
- [The krit layer (opinionated)](#the-krit-layer-opinionated)
- [Host-specific values](#host-specific-values)
- [What is declared, what is not](#what-is-declared-what-is-not)
- [Behaviour worth knowing](#behaviour-worth-knowing)
- [Known issues](#known-issues)

## How it is organised

The feature is split into two layers that follow the repo-wide rule "generic base in `modules/`, personal choices in `users/krit/`":

| Layer | File | Role |
|---|---|---|
| Generic module | `modules/nixos/specializations/ryoku.nix` | Anyone can enable it. Imports the Ryoku NixOS module, creates the user, forces off what would clash, exposes the options. Holds no personal values. |
| Bind companion | `modules/nixos/specializations/ryoku-binds.nix` | Renders this repo's keybinds into Ryoku's files (shared pure helpers also used by the Hyprland, niri and Mango bind modules). |
| krit layer | `users/krit/nixos/specializations/ryoku.nix` | Our opinions: the declared Ryoku settings, SDDM cursor, personal config, clone units, the fastfetch wrapper. |
| Host files | `hosts/<host>/default.nix` | Per-machine overrides (for example the bar scale and suspend policy on the desktop). |

Ryoku is x86_64-linux only (an assertion fails elsewhere). Its module is imported by the flake input but only activated inside the specialization; the base system is unaffected unless the entry is selected.

## The generic module

**The account.** The entry has its own user `<constants.user>-ryoku` (own uid, subuid range, home and Home Manager user). The base user does not exist in it, and `constants.user` is rewritten to the Ryoku user inside the entry, so every module that reads it follows.

**What is forced off so Ryoku owns the session.** hyprland, niri, mango, kde, gnome, cosmic, bluetooth, qt, caelestia, noctalia, walker, vicinae, skwd-wall, fastfetch, starship, swayosd, the waybar variants, auto-cpufreq, tlp, coffee, hypridle, swaync and both SDDM themes. Options a host does not declare are skipped. Mango is not offered at all: the Ryoku NixOS port supports only Hyprland and niri, and its session is filtered out of the display manager. The stock Hyprland, Hyprland (uwsm) and niri sessions stay available as a rescue.

**Theming.** Stylix runs in a reduced form (`autoEnable = false`): bat, blender, cava, fzf, gdu, gedit, lazygit, nixcord, tmux, zathura and zen-browser are themed; gtk, hyprland, kde, kitty, starship, swaync and yazi are not (Ryoku styles those itself). The catppuccin constant is forced off.

**Options.**

| Option | Purpose |
|---|---|
| `settings` | Attribute set of JSON values keyed by Ryoku store (`desktop`, `shell`, `launcher`, `matugen`, `ryogami`, `performance`, `power`, `power-profile` and the other allowed stores). Merged into `~/.config/ryoku/<store>.json` by the `ryoku-settings-seed` user service before the shell starts. Empty = nothing generated. |
| `settingsMode` | `seed-once` (default) applies each store once per declaration hash, so GUI edits of declared keys survive until the declaration changes. `enforce` re-applies the declaration at every login. |
| `fastfetchEmblem` | Optional PNG imported once through the Hub's own import. Unused by our layer (see fastfetch below). |
| `sddmCursorTheme`, `sddmCursorPackage`, `sddmCursorSize` | Cursor for the SDDM greeter. Null leaves the greeter untouched. |
| `user`, `home` | Read-only: the entry's account and home directory. |

**Guard rails (assertions).** Unknown stores are rejected. The secret stores `hub` and `i18n-llm` and `shell.python.general.location` (volatile personal data) can never be declared because the repo is public. A declared static Ryoku theme must match `constants.theme.polarity`. The entry fails to build on non-x86_64.

**Derived from constants.** Unless a host or layer overrides them (`mkDefault`):
- the five default apps in `desktop.json` (browser, terminal, editor, files, notes) come from `constants.browser`, `terminal`, `editor` and `fileManager` (terminal apps start as `<terminal> -e <app>`);
- the keyboard is the first entry of `constants.keyboardLayout` and `keyboardVariant` (Ryoku is single-layout, no group toggle, natural scroll off);
- the colour polarity of Ryoku's matugen store comes from `constants.theme.polarity`.

**System plumbing.** The portal routing is forced to this repo's shared table so Ryoku's own lists do not concatenate with it. `ryoku update` points at `/var/empty` (updates only happen through this flake: `nix flake update ryoku`). `/var/lib/ryoku` is persisted on impermanence hosts and the Ryoku SDDM theme is re-seeded after the persist mount. SDDM's weston kiosk compositor is replaced by a generated command that carries the cursor theme (the kiosk shell draws no pointer of its own).

## The krit layer (opinionated)

- **Declared settings** (full list below).
- **Keybinds**: the same binds as the base entry, rendered into Ryoku's late-loaded `hypr/user.lua` and `niri/user.kdl` with Ryoku's own launcher, lock, screenshot and volume/brightness commands. Chords with no Ryoku equivalent are dropped; a chord that clashes with a Ryoku default replaces it.
- **Personal config**: kitty content in `kitty/user.conf`, fish in `fish/user.fish`, yazi through `YAZI_CONFIG_HOME=~/.config/yazi-user` (including its `g` go-to chords, `g M` for the momentary folder among them), nvim and starship seeds. Our kitty settings load last, so Ryoku's font changes do not show in kitty.
- **Services that stay on**: ssh-config, cloud and NAS mounts, home.base and the dotfiles-private links. The borg backup modules and the wallpapers link are off.
- **Repo clones**: three user units, `ryoku-dotfiles-sync`, `ryoku-nix-sync` and `ryoku-dotfiles-private-sync`, create full clones of `~/dotfiles`, `~/nix` (the flake directory) and `~/dotfiles-private` (over SSH with the entry user's `~/.ssh/id_github`, a pinned Gitea host key and strict host-key checking). An existing checkout is fast-forwarded only when it is clean, fully pushed and has an upstream; it is never reset, so work in progress is safe. Shallow leftovers heal themselves. The clones are separate working copies from the base user's.
- **SDDM cursor**: Bibata-Modern-Ice, size 24.
- **Fastfetch**: the logo is chosen in the Hub (the hawk). A shell-independent `ryoku-fastfetch` wrapper takes priority in PATH, so the bash, zsh and fish greetings all use it:
  - plain kitty or ghostty: Ryoku's own script, untouched;
  - tmux under kitty: the real image, sent through tmux passthrough and drawn as unicode placeholders beside the info text (the upload is cached and re-sent each run);
  - other terminals and multiplexers (herdr and similar): the image rendered once as a text sprite and cached;
  - the Hub's logo type decides: only image logos get this treatment, any other type (built-in, text file, command, none) is passed to Ryoku's script untouched.

## Host-specific values

| Host | Declared in `hosts/<host>/default.nix` |
|---|---|
| `nixos-desktop` | Bar scale `shell.orpheus.scale = 1.3` (the scaled monitors made the default bar look small); no suspend (`power.idle.*.suspendSec = 0`). |
| `nixos-laptop` | Nothing extra: it uses the shared defaults (bar scale 1.0, suspend after 15 min on battery and 30 min on AC). |

The idle timeouts differ per host because they follow each host's own hypridle options.

## What is declared, what is not

**Declared in Nix** (the keys below are written into the stores; with `seed-once` a Hub edit of a declared key survives until its declaration changes):

| Store | Declared keys |
|---|---|
| `desktop` | Gaps in 6, gaps out 12, rounding 4; middle-button emulation and workspace swipe on; Hyprland dwindle `preserveSplit`; default apps and keyboard derived from constants. |
| `shell` | Font (JetBrainsMono Nerd Font Mono), `deckFrost` 0.5, bar style `orpheus`, weekly clipboard prune, metric temperature, static theme Dracula with matugen (contrast 0, mode from polarity, preference Darkness, scheme Expressive). Desktop only: `orpheus.scale` 1.3. |
| `launcher` | Background blur 8, hero strength, no greeting, hero image from the Ryoku user's `Pictures/Wallpapers`. |
| `matugen`, `ryogami` | Polarity from the constants, expressive scheme, fixed Dracula theme policy, wallpaper mute, shader transitions (900 ms, random), overview backdrop blur, `slices` wallpaper selector. |
| `power-profile` | `performance` (AC and desktop). |
| `performance` | `autoPowerSaverOnBattery = true`: Ryoku switches to Power Saver when unplugged and restores the previous profile on AC. |
| `power` | Power Saver redefined as the middle ground (governor `powersave`, energy preference `balance_power`, 90% frequency ceiling) and the idle policy: dim, lock and screen off follow the host's hypridle options on both AC and battery, `onDesktops` on, suspend 900 s on battery and 1800 s on AC (0 on the desktop). |

**Owned by Nix but not a store** (re-laid on every activation or login, so in-place edits are lost): the keybind files `hypr/user.lua` and `niri/user.kdl`, `kitty/user.conf`, `fish/user.fish` and the yazi link farm; the stylix-lite targets and the forced-off list.

**Left to Ryoku (change it in the Hub or shell, it persists in the Ryoku user's home):**
- monitor layout and output profiles (deliberately not declarable: `ryoku-monitor` regenerates them per hardware id and declaring them would pin the layout);
- the wallpaper choice, volatile state (stage, widgets, equalizer, locks);
- the fastfetch logo and layout;
- every key of a store that is not declared (for example the bar layout and the other `shell.json` keys);
- the secret stores (`hub`, `i18n-llm`): never declarable.

A fresh Ryoku home loses all GUI state and is re-seeded from the declarations.

## Behaviour worth knowing

- **Settings apply at login**, not at rebuild: `ryoku-settings-seed` runs between `ryoku-materialize` and `ryoku-shell`. With `seed-once` a changed declaration applies once at the next login of the entry; a Hub edit made after that survives until the declaration changes again.
- **Power**: the Hub also edits `power.json`; the declared keys are only the ones listed above. The AC/battery switch is Ryoku's: Power Saver on battery is the strictest profile by default, which is why it is redefined here.
- **Idle**: Ryoku's own idle daemon replaces hypridle in the entry. It has no equivalent of the "skip while a nix build runs" guard of the hypridle module.
- **Updates**: only through this flake. Ryoku's Hub updater is disabled on purpose.
- **First build**: Ryoku brings an older pinned nixpkgs (including mesa), patched quickshell and niri; several packages build locally the first time and only `ryotunes.cachix.org` caches them.

## Known issues

- **SDDM cursor on the laptop** is intermittently not drawn in the greeter (the pointer works, it is just invisible). The weston log is clean and the cursor theme is set; the suspected cause is the hardware cursor plane on the laptop GPU. It is accepted as a known issue; the desktop is unaffected.
- The first SDDM greeter attempt can exit with code 1 and restart; the second one works.
- Runtime items not yet verified on hardware (session startup, first-login pickup of settings, the Hub never rewriting `user.*`, SSH signing from the Ryoku clone) are tracked in the checklist of [`ryoku-specialization.md`](usage/gotchas/ryoku-specialization.md).
