---
name: laptop-audio-74rc2-num-components
description: nixos-laptop audio dead on 7.4-rc2 = ASoC rtd->num_components preset by devm_kzalloc_flex (__counted_by); "(null) Speaker Volume limit set failed: -22"; fixed upstream d00ba321499c
metadata:
  type: project
---

7.4-rc2 (2026-11-14 first boot) killed all laptop audio with a NEW signature, not the old
cs35l56 spk-id-gpios EBUSY: `sof_sdw: (null) Speaker Volume limit set failed: -22` ->
`snd_soc_register_card failed -22`, and NO "loading topology" lines at all. 7.4-rc1 without the
CVS patch worked (boots 2026-11-13/14), so the CVS removal was fine.

**Why:** treewide commit 4dd10fbbeb9c switched soc_new_pcm_runtime() to devm_kzalloc_flex();
components[] is `__counted_by(num_components)`, so the allocator presets num_components to the
slot count. for_each_rtd_components() stops at the NULL slot 0 -> no components probed (no
topology, name_prefix stays NULL -> "(null)") and add_component writes past the array.
Hits every ASoC card on that kernel. Fix: d00ba321499c "ASoC: soc-core: reset
rtd->num_components after allocation" (master 2026-11-10, NOT in v7.4-rc2; expected rc3).

**How to apply:** "(null) <X> Volume" / missing topology lines on an rc kernel -> suspect core
ASoC, diff kernel logs vs previous boot (`journalctl -k -b -1 -o cat`), and list
`gh api repos/torvalds/linux/commits -f sha=master -f path=<file>` for a fix. Drop any vendored
backport once linux_testing >= 7.4-rc3. Related: [[laptop-audio-kernel-72-regression]].
