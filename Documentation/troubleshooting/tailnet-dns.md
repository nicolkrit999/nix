# Tailnet DNS outages - what this repo has to do with it (2026-09-09)

Recurring "the internet is completely down" while Tailscale is up. **Nothing in
this repo caused it and no repo change fixed it.** Cause and fix were both on the
tailnet admin console side (DNS -> Global nameservers). Only the parts that touch
this configuration are recorded here.

## `modules/nixos/services/resolved.nix` is exonerated

While Tailscale is up, tailscaled overrides the system resolver configuration
wholesale, so `FallbackDNS` and `Domains = "~."` in that module are inert.
Confirmed by tcpdump on `tailscale0`. Do not re-investigate it for this class of
outage.

## Never put `--accept-dns=false` in `extraSetFlags`

`modules/common/services/tailscale.nix` line ~55. It was the manual escape hatch
during the outage - it stops tailscaled pushing DNS so `resolved.nix` takes over -
and it is now obsolete. Declaring it would mean Quad9 always, AdGuard blocking
never, no MagicDNS: the opposite of the intent (AdGuard when possible, Quad9 when
not, nothing to run or toggle).

## The `tailscalenodeset` / `tailscalenoderemove` helpers are shell-gated

Same module gates them on `myconfig.constants.shell`. Fish gets
`programs.fish.functions`, bash/zsh get POSIX equivalents. Any script must not
assume the fish functions exist - call `tailscale set` directly.

## One-line field diagnosis

During a drop: `ping 1.1.1.1` succeeds while `ping google.com` fails => this DNS
class, nothing to do here. **Both failing => a different bug entirely.**

## Timestamp caveat when correlating logs on nixos-desktop

This host's RTC reads local time, so `boot -1` timestamps run backwards and
`journalctl --since/--until` silently returns nothing for the incident window.
Grep the whole boot instead.
