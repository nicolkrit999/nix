# Coffee mode

Coffee mode keeps a Hyprland, niri or mango machine working as if someone were sitting at it:
no automatic sleep, no idle dim/lock/screen-off, and closing the lid does nothing. It stays on
until `coffee-off` or a reboot, also across logout and with the lid closed.

Module: `modules/nixos/services/power/coffee.nix` (`myconfig.services.coffee.enable`, default
`true`). It is installed only when Hyprland, niri or mango is enabled, and is forced off in the
`guest` and `secure-travel` specialisations.

## Commands

| Command | What it does |
|---------|--------------|
| `coffee-on` | Starts the transient user unit `coffee.service`, which holds the logind locks below. Enables lingering (if it was off) so the unit, and your tmux panes, survive logout. Refreshes the waybar pill and sends a notification. |
| `coffee-off` | Stops the unit, turns lingering off again only if `coffee-on` turned it on, then checks that no coffee lock is left in `systemd-inhibit --list`, no `coffee.service` is left, lingering is back to how it was, and hypridle is running. Refreshes the pill and sends a notification. |
| `coffee-status` | Prints ON / OFF / INCONSISTENT, the unit, linger and hypridle state, and the block/block-weak lines of `systemd-inhibit --list`. Exit code: 0 on, 3 off, 1 inconsistent. |
| `coffee-toggle` | Uses the same state test as `coffee-status` and runs `coffee-off` when coffee is ON or INCONSISTENT, `coffee-on` when it is OFF. Prints and journals one `coffee-toggle: coffee is <state>, running <script>` line, then the output and exit code are those of the script it ran. The waybar pill's left-click runs it. |

`coffee-on` and `coffee-off` print one line per step, `[ OK ]`, `[WARN]` or `[FAIL]` (coloured
only on a terminal), and every `[WARN]`/`[FAIL]` line ends with `fix: <command>`, the single
command that repairs that step. The same lines go to the journal:

```bash
journalctl --user -t coffee -b      # or: journalctl -t coffee -b
```

The last line is a summary. The exit code is non-zero if any step failed. Running either command
twice is safe: the second run reports that coffee was already on/off.

## What is blocked, what still works

`coffee.service` runs two nested `systemd-inhibit` holders:

| Lock | Mode | Effect |
|------|------|--------|
| `sleep` | `block-weak` | logind-initiated automatic suspend/hibernate, and requests from other users (for example a greeter), are refused. |
| `idle:handle-lid-switch` | `block` | hypridle's dim, lock and screen-off listeners never fire; logind ignores the lid. |

Still working while coffee is on (deliberate actions and emergencies):

- manual `systemctl suspend` / `systemctl hibernate` (a weak lock does not stop its own user),
- the suspend and hibernate keys (the module sets logind `SuspendKeyIgnoreInhibited=yes` and
  `HibernateKeyIgnoreInhibited=yes`),
- the power button, `poweroff`, `reboot`, `shutdown` (coffee never takes `shutdown` or
  `handle-power-key`),
- manual lock binds (`loginctl lock-session`),
- the upower critical-battery action (it falls back to power-off here) and the kernel thermal
  shutdown.

## Limits

- Start it from a terminal in the local graphical session. Over SSH with nobody logged in
  locally, logind refuses the lid lock: `coffee-on` reports `[FAIL]` and removes the unit again.
- KDE, GNOME and COSMIC have their own power managers. `coffee-on` still runs there, but prints a
  `[WARN]` with the command that opens that desktop's power settings.
- Surviving logout keeps the machine and the user manager alive. Jobs in a plain terminal window
  still die with the compositor; run long jobs inside tmux. Open live check: confirm once that a
  tmux pane survives `coffee-on`, logout, login.
- See the gotcha [coffee mode with the lid closed](../gotchas/coffee-mode-lid-closed.md).

## Waybar

`custom/coffee` sits right after `battery` in all three waybars and is always shown. It is drawn
like the microphone pill (`custom/mic`): a plain pill with one coloured icon, no ring and no level
bar.

| State | `class` | Text | Tooltip |
|-------|---------|------|---------|
| on (`coffee.service` active) | `active` | cup 󰅶 (U+F0176) in the `base0F` accent | Coffee mode on: no automatic sleep, idle lock or lid action. Click to turn it off |
| off | `off` | struck cup 󰾪 (U+F0FAA) in the `base08` accent, like the muted microphone 󰍭 | Coffee mode off. Click to turn it on |

Both accents go through the contrast helper (`accentOn base01 3`), so they keep at least 3:1 on the
pill in every scheme. Left-click runs `coffee-toggle` by store path
(`myconfig.services.coffee.togglePackage`), so it works even when waybar's `PATH` has no coffee
commands; the notification comes from `coffee-on` / `coffee-off`. Right-click does nothing. The
scripts refresh the pill with `pkill --signal RTMIN+8` (waybar `signal = 8`), and it re-polls
every 5 s, so it also corrects itself after a reboot or when the unit dies.

## Script layout and test hooks

The scripts live in `modules/nixos/services/power/coffee/`: `coffee-lib.sh` is prepended to
each of `coffee-on.sh`, `coffee-off.sh`, `coffee-status.sh` and `coffee-toggle.sh`. Every external command is called
by name, so a test can put stubs first. Environment overrides:

| Variable | Default | Purpose |
|----------|---------|---------|
| `COFFEE_PATH_PREFIX` | unset | Prepended to `PATH` (stub directory). |
| `COFFEE_STATE_DIR` | `${XDG_STATE_HOME:-~/.local/state}/coffee` | Linger marker and the hypridle state recorded at `coffee-on`. |
| `COFFEE_TRIES` / `COFFEE_POLL` | `15` / `0.2` | Verification polling (tries, seconds between). |
| `COFFEE_BOOT_ID` | `/proc/sys/kernel/random/boot_id` | Boot id stored in the linger marker; a marker from another boot is ignored. |
| `COFFEE_COLOR` | `auto` | `always` / `never` force colour on or off. `NO_COLOR` is honoured in `auto`. |
| `COFFEE_USER` | `$USER` | User passed to `loginctl`. |

The test `templates/tests/nixos/test-coffee/` (`bash templates/tests/run-tests.sh --only nixos-coffee`)
uses these hooks to run the real scripts against stub systemd/logind tools, and checks the module
contract on a fake host; see its `test-coffee-readme.md`.
