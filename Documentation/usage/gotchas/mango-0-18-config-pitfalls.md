# MangoWM 0.18 config pitfalls

Non-obvious behaviours of mango 0.18.0 that shaped `modules/nixos/programs/de-wm/mango/` and `hosts/nixos-desktop/default.nix`.

- **Keyword rename.** 0.18 renamed the config keywords to snake_case (`isfloating` -> `is_floating`, `appid` -> `app_id` in rules, `exec` -> `exec_once`, ...). Old names are rejected line by line at load time. The error bar stores several lines per bad config line and shows only the first 3 plus a `+N more` count, so N is not the number of bad lines.
- **`mango -p` exit code is unreliable.** Any keybind conflict makes `mango -p` exit 0 even when there are unknown or rejected keywords (load.c:422, `result = parse_correct || keybindings_conflict`), so a conflict hides parse errors. A check must also require empty stdout and stderr.
- **Config values are silently cut at 255 characters.** mango reads each line with `sscanf("%255[^=]=%255[^\n]")` (src/config/load.c:87-88) and drops the rest without any error; `mango -p` still passes. A long `exec_once` becomes broken shell (`sh -c` fails with an unmatched quote), the program never starts and nothing is logged. This is why the wallpaper never started in mango while Hyprland and niri worked. Fix in repo: `mk-wallpaperd.nix` provides a short `<wm>-wallpaperd-start` launcher (logs to `$XDG_RUNTIME_DIR/<wm>-wallpaperd.log`), and `mango-main.nix` fails the build if any `exec_once`/`window_rule`/`window_rule_once`/`monitor_rule` value exceeds 255 characters. `test-wallpaperd-runtime` checks it too. Keep long commands in a script and put only its path in the config.
- **`window_rule_once` re-arms on every reload** (option_defs.c:1312-1317), including `nh os switch` and SUPER+SHIFT+R. The `windowRulesOnce` option exists but no host sets it; one-time placement of zen is done by `mango-place` on the startup line instead. Note the IPC client JSON field is `appid`, not `app_id`.
- **Rule values of 0 do nothing.** Opacity rule values only apply when above 0 (parse.h:29-31); use `0.01`.
- **`switch_proportion_preset` needs `next`.** With no argument it steps backwards.
- **DPMS is "output disabled".** Mango's screen-off disables the output, so tools cannot tell asleep from disabled, and `wlopm --on '*'` re-enables outputs configured with `disable:1` (the JetKVM). hypridle therefore uses `mango-dpms`, which only wakes outputs it turned off itself.
- **Pinned windows count as visible on every tag**, so `mango-scratch` filters on `is_global`/`is_unglobal`.
- **`GDK_SCALE` must be 1 under mango.** Xwayland gets the logical size and the compositor scales X11 clients; `GDK_SCALE=2` would make X11 GTK/Java apps about 3x. It is set through `settings.env` because the session variable file exports `GDK_SCALE=2` whenever the first monitor is scaled, in every session (needed by Hyprland with `force_zero_scaling`).

Upstream limits (no repo fix possible):

- No mirror option; no way to turn off the error bar (mangonag, upstream #1492).
- Every handled bind repeats while held (keyboard.c:724).
- 9 tags only: no SUPER+0, no pinch gesture.
- The special tag's state is hidden from IPC (ipc.c:543-555); an active but empty special tag is misread until the next arrange.
- Zen ignores `--class` on Wayland, so the scratch browser cannot have its own float/size rule.
