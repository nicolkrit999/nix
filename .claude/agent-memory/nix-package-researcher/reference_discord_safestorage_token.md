---
name: discord-safestorage-token
description: Official Discord desktop uses Electron safeStorage for its token (dQw4w9WgXcQ: prefix in Local Storage); password-store switch can log out; cookies plaintext in observed profile
metadata:
  type: reference
---

Official Discord (nixpkgs `discord`, 1.0.161) calls `safeStorage.encryptString`/`decryptString` via IPC in `~/.config/discord/1.0.161/modules/discord_desktop_core/core.asar`. The token is read from Local Storage: encrypted tokens carry a `dQw4w9WgXcQ:` prefix and are decrypted with safeStorage; on decrypt failure it logs "Token decryption failed" and falls back to a plaintext match.

**Why:** the safeStorage key lives in the keyring selected by `--password-store`. Changing the backend (no flag -> basic/kwallet, or flag -> gnome-libsecret) makes decrypt fail, so the login is lost.

**How to apply:** pin discord with `commandLineArgs` (package.nix accepts it and passes it to the wrapper). Do NOT exclude `~/.config/discord/Local Storage` or `Cookies` from borg.

Also: the observed profile had 0 `dQw4w9WgXcQ:` markers and Cookies with plaintext `value` (encrypted_value empty), no `os_crypt` key in Local State. Unexplained, so do not assume Chromium v10/v11 cookie encryption. See [[secret-service-single-provider]] (repo doc) for the flag mechanism.
