# Coffee mode with the lid closed

With coffee mode on ([usage](../power/coffee-mode.md)) closing the laptop lid does nothing, on
purpose. That has consequences:

- **The session stays unlocked.** Coffee blocks the idle lock and the lid action, and nothing
  locks on lid close. Whoever opens the lid gets the running session. Lock by hand first
  (`loginctl lock-session` or the lock bind) if the laptop leaves your sight; locking does not
  stop any process.
- **Heat.** The machine keeps running at full speed (on AC auto-cpufreq uses the performance
  governor) with less airflow. Never put it in a bag with coffee on: the kernel thermal trip
  powers it off hard, and unsaved work and running builds are lost.
- **Battery.** At the upower critical level (2 %) the machine still powers off (hibernate is not
  available here, so the configured action falls back to power-off). Coffee does not and cannot
  stop that.
- **`coffee-off` with the lid still closed suspends right away.** logind re-checks the lid once
  the lock is gone. `coffee-off` prints a `[WARN] lid: closed ...` line first.
- Coffee does not turn the internal panel off on lid close. With an external monitor, niri
  disables the internal panel by itself (niri behaviour, unrelated to coffee).
