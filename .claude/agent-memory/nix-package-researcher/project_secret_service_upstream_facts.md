---
name: secret-service-upstream-facts
description: Verified nixpkgs/kwallet facts behind the single-Secret-Service-provider decision (ksecretd keys, Plasma kwallet pull-ins, portal Secret routing gaps)
metadata:
  type: project
---

Facts verified 2026-10-09 against locked nixpkgs (store 2010s04mqpq7q1kch0ddc9b429s2vh9v) and live /etc/xdg:

- kwallet 6.30.0 kcfg (share/config.kcfg/kwalletsettings.kcfg) has three independent switches: [Wallet] Enabled (kwalletd6, default true), [KSecretD] Enabled (ksecretd, default true), [org.freedesktop.secrets] apiEnabled (fdo API, default true). RESOLVED since: modules/nixos/toplevel/kde.nix now writes /etc/xdg/kwalletrc with [Wallet] Enabled=true, [KSecretD] Enabled=false, [org.freedesktop.secrets] apiEnabled=false (verified 2026-10-11).
- Plasma 6 module pulls kwallet via plasma6.nix:98-100 and xdg.portal.extraPortals (plasma6.nix:300). excludePackages does not remove it.
- As of 2026-10-09 the live /etc/xdg/xdg-desktop-portal/*-portals.conf had no Secret key except mango (Secret=gnome-keyring), and the /etc copy overrides the package kde-portals.conf (Secret=kwallet). RESOLVED since: modules/nixos/toplevel/xdg-portal.nix now defines `secretPortal = { "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ]; }` (mkForce, line ~59) plus a manifest-only portal declaring the Secret interface. Not re-verified against a built /etc.
- xdp 1.22 (verified 2026-10-11): UseIn is only a deprecated fallback, NOT a loading gate; portals load from every XDG_DATA_DIRS entry (HM share first, same-named later copies skipped); NIX_XDG_DESKTOP_PORTAL_DIR is ignored. Routing follows layered *-portals.conf files. Repo patchPortalPkg now only patches xdg-desktop-portal-wlr; gnome-keyring.portal is UseIn=gnome upstream but that does not affect Secret routing (config routes by name). See Documentation/usage/gotchas/xdg-desktop-portal-nixos.md.
- ~/.local/share/kwalletd does not exist, so no KWallet data needs migrating.

Why: needed to choose the single provider without KWallet clashes.
How to apply: when editing kde.nix kwalletrc, xdg-portal.nix or home-nixos.nix dbus stubs, keep all three kwallet switches and the Secret portal routing consistent with these facts. See Documentation/usage/gotchas/secret-service-single-provider.md.
