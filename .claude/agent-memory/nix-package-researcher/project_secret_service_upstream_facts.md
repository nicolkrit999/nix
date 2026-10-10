---
name: secret-service-upstream-facts
description: Verified nixpkgs/kwallet facts behind the single-Secret-Service-provider decision (ksecretd keys, Plasma kwallet pull-ins, portal Secret routing gaps)
metadata:
  type: project
---

Facts verified 2026-10-09 against locked nixpkgs (store 2010s04mqpq7q1kch0ddc9b429s2vh9v) and live /etc/xdg:

- kwallet 6.30.0 kcfg (share/config.kcfg/kwalletsettings.kcfg) has three independent switches: [Wallet] Enabled (kwalletd6, default true), [KSecretD] Enabled (ksecretd, default true), [org.freedesktop.secrets] apiEnabled (fdo API, default true). Repo kwalletrc sets only the first and third; [KSecretD] Enabled=false is missing.
- Plasma 6 module pulls kwallet via plasma6.nix:98-100 and xdg.portal.extraPortals (plasma6.nix:300). excludePackages does not remove it.
- Live /etc/xdg/xdg-desktop-portal/*-portals.conf: no Secret key in kde, niri, cosmic, hyprland, gnome, portals.conf. Only mango has Secret=gnome-keyring. /etc copy overrides the package kde-portals.conf (Secret=kwallet). R2 claims were partly wrong.
- Repo patchPortalPkg rewrites UseIn only for gtk and kde portal packages. gnome-keyring.portal is UseIn=gnome.
- ~/.local/share/kwalletd does not exist, so no KWallet data needs migrating.

Why: needed to choose the single provider without KWallet clashes.
How to apply: when editing kde.nix kwalletrc, portal config, or home-nixos.nix dbus stubs, add the missing pieces listed here.
