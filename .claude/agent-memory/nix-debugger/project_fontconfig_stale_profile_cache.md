---
name: fontconfig-stale-profile-cache
description: GTK text renders as tofu after a font move between HM and system - stale ~/.cache/fontconfig entry for /etc/profiles/per-user/krit/share/fonts/<subdir>; fix with fc-cache -r
metadata:
  type: project
---

HM `fonts.fontconfig.enable` adds `<dir>/etc/profiles/per-user/krit/share/fonts</dir>`, a non-unique path. Every subdir symlink resolves to a store dir with mtime 1, so fontconfig's mtime check always passes and the old `~/.cache/fontconfig` entry (newer file mtime than the profile's own store cache) wins. When a package leaves the HM profile but the subdir name stays (e.g. `noto/` held noto-fonts + emoji, now emoji only), fc-match still returns files that no longer exist. Pango/cairo then logs `failed to create cairo scaled font ... font_face status is: file not found` and every glyph draws as a box. Seen on 2026-10-09 after stylix sans/serif moved from noto-fonts to JetBrains (3e88fcb6). It hit xdg-desktop-portal-gtk and swayosd.

**Why:** shell `fc-match` looks fine because it returns a path. The breakage only shows when you check `[ -e "$file" ]` or look in the journal for "file not found".

**How to apply:** on tofu reports, run `journalctl --user -b | grep 'scaled font'`, then `fc-list : file | grep per-user` with an existence test. To confirm, run `XDG_CACHE_HOME=<empty dir> fc-match -f '%{file}' 'X'`. Fix with `fc-cache -r` and restart the affected user services. No repo change is needed.
