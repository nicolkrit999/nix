# test-librewolf-profiles

Eval-level contract of the LibreWolf two-profile setup (`users/krit/common/programs/gui-programs/librewolf/`, batch 11 of the codebase audit) on the REAL `nixos-desktop` and `nixos-laptop` configurations: profile layout, the prefs written to each `user.js`, the Privacy exit-wipe wiring, search engines, extensions, and the secure-travel specialisation that makes Privacy the default profile.

This test only proves what the generated `user.js` and `librewolf.overrides.cfg` SAY. LibreWolf's `mozilla.cfg` `pref()` calls run after `user.js`, so the generic `programs.librewolf` module (`modules/common/programs/librewolf.nix`, fed by `krit.programs.librewolf` through `profileSettings`) re-asserts each profile's prefs in `~/.librewolf/librewolf.overrides.cfg` (evaluated last, selected per profile by the `nixcfg.librewolf.profile` marker pref in `user.js`); whether they TAKE EFFECT is proven by `test-librewolf-runtime`.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-librewolf-profiles` (name as shown by `--list`); the direct command is below.

From the repo root:

```bash
bash templates/tests/nixos/test-librewolf-profiles/check-nixos-librewolf-profiles.sh
```

Or from inside the directory:

```bash
bash check-nixos-librewolf-profiles.sh
```

Needs `nix`, `jq`, `bash`. Eval-only (no builds), about 12 s for both hosts.

## How it works

`01-scenario-librewolf-profiles.nix` takes `{ host }`, loads `flake.nixosConfigurations.<host>` via `builtins.getFlake` (`FLAKE_ROOT` from the runner) and layers an `extendModules` twin that forces `krit.programs.librewolf.enable` on, so the result does not depend on which host enables the module. It parses the generated `.librewolf/<profile>/user.js` text back into an attribute set (the artifact LibreWolf reads, including the stylix additions) and asserts on it, on `profiles.ini`, on the HM `programs.librewolf` options and on the secure-travel specialisation config.

A second twin ("mutant") breaks the config on purpose (Privacy wipe/WebGL/FPP/allow-list prefs reverted, `librewolf.overrides.cfg` emptied, dead v1 prefs and `lifetimePolicy` re-added, Default wipe on, DoH exclusions emptied, a `Cookies` policy added, search default, extension list, profile id, desktop entry and stylix profile names changed, secure-travel with Zen and PWAs on and Privacy no longer default). Every check that has a mutation listed in `mustFail` must report FAIL on the mutant while passing on the real config, so none can pass vacuously. The `check-*.sh` refuses to pass with fewer than 60 checks.

Which hosts enable LibreWolf is a host choice and is not asserted.

## Checks

Evaluated once per host (desktop and laptop), 46 results each.

### Layout and consistency
| Check | Expected |
|-------|----------|
| profiles | exactly `default` (id 0, name Default) and `privacy` (id 1, name Privacy) |
| profiles.ini | exactly one `Default=1`, and it is the Default profile |
| base default profile | `default.isDefault` true, `privacy.isDefault` false outside secure-travel |
| no policies / wrapper | `programs.librewolf.policies == { }`, stock `librewolf` package, no `policyroot` file, no `MOZ_APP_DISTRIBUTION` session variable |
| stylix | `stylix.targets.librewolf.profileNames` equals the HM profile names |
| desktop entry | `librewolf-privacy` exists and runs `librewolf -P <Privacy profile name> --no-remote` |
| search | both profiles: default and privateDefault `kagi`, order `kagi`, `ddg`, no perplexity/google engine, alias `@k`; wikipedia, mojeek, startpage hidden |
| extensions | 14 in Default, 6 in Privacy, Privacy a subset of Default, no empty names |

### Prefs of both profiles
| Check | Expected |
|-------|----------|
| shared prefs | `autoDisableScopes` 0, FxA off, no password manager or autofill, new-tab junk off, category `strict`, `sidebar.main.tools` `history,bookmarks`, DoH mode 2 with the Quad9 URI, RFP false |

### Default profile
| Check | Expected |
|-------|----------|
| no exit wipe | `sanitizeOnShutdown` false (LibreWolf's default is true), `browser.startup.page` 3 |
| DoH exclusions | `network.trr.excluded-domains` is the internal-name list |
| web compatibility | notifications, EME, Widevine and Widevine updates, WebRTC, webauthn, ETP convenience allow-list all on |
| no dead overrides | none of the removed tracking-protection, cookieBehavior, firstparty, lifetimePolicy, sameSite, referrer, popup, u2f, credentialmanagement or defaultsUrl prefs; no `privacy.clearOnShutdown*`; WebRTC ICE and WebGL left at default |

### Privacy profile
| Check | Expected |
|-------|----------|
| fingerprinting | FPP overrides `+AllTargets,-CSSPrefersColorScheme,-CanvasImageExtractionPrompt`, RFP false, `webgl.disabled` true |
| WebRTC, DRM, HTTPS, referrer | ICE `default_address_only` and `no_host` true, EME and Widevine off, HTTPS-Only on, XOriginPolicy 1, trimming 2 |
| DoH | mode 2 (captive portals), `custom_uri` equals `uri`, `ts.net` excluded |
| captive portal | detection enabled with the canonical URL, connectivity service not enabled |
| exit wipe | `sanitizeOnShutdown` and the five `privacy.clearOnShutdown_v2.*` prefs true |
| no dead wipe prefs | no `lifetimePolicy`, `firstparty.isolate`, `disablePrefetch`, `privatebrowsing.autostart`, no v1 `privacy.clearOnShutdown.*` |
| allow-list wiring | `permissions.manager.defaultsUrl` is a `file:///nix/store/...-librewolf-privacy-permissions` URL |
| overrides.cfg | reads the `nixcfg.librewolf.profile` marker, the markers in the two `user.js` are `default`/`privacy`, the `privacy` block re-asserts `webgl.disabled`, `permissions.manager.defaultsUrl`, `network.captive-portal-service.enabled` and `captivedetect.canonicalURL` with the `user.js` values, the `default` block sets none of them |

### secure-travel specialisation
| Check | Expected |
|-------|----------|
| default profile | HM `privacy.isDefault` true, `default.isDefault` false, `profiles.ini` has one `Default=1` and it is Privacy |
| other browsers | Zen, PWAs, stock Firefox, Chromium and Helium all off |
| GNOME pin | the pinned apps contain `librewolf-privacy.desktop`, not `zen-beta.desktop`, and that entry exists in the spec's HM config |

### Controls
| Check | Expected |
|-------|----------|
| disabled module | with the module forced off there is no Privacy `user.js` (the enabled twin has it) |
| mutant fails X | for each of the 20 checks that have a mutation, the mutant makes it FAIL while it passes on the real config |
