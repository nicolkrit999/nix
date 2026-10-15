#!/usr/bin/env python3
"""Headless LibreWolf runtime checks. Prints one TSV line per check: label<TAB>ok|FAIL: detail."""
import json
import os
import re
import shutil
import signal
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlparse

EXEMPT_NO_DEFAULT = {
    "browser.contentblocking.category",
    "browser.download.dir",
    "browser.download.lastDir",
    "browser.tabs.warnOnCloseOther",
    "ui.systemUsesDarkTheme",
}
EXEMPT_PREFIX = ("font.", "reader.")
NOT_COMPARED = {"browser.uiCustomization.state"}
BOGUS = "librewolf.test.bogus-pref-that-gecko-does-not-know"
UNLISTED_HOSTS = ["unlisted.example.org", "other.example.net"]
RESULTS = []


def report(label, problems):
    RESULTS.append((label, "ok" if not problems else "FAIL: " + "; ".join(problems)))


class Marionette:
    def __init__(self, port, timeout=90):
        deadline = time.time() + timeout
        while True:
            try:
                self.s = socket.create_connection(("127.0.0.1", port), timeout=5)
                break
            except OSError:
                if time.time() > deadline:
                    raise
                time.sleep(0.3)
        self.s.settimeout(timeout)
        self.buf = b""
        self.n = 0
        self._recv()

    def _read(self):
        d = self.s.recv(65536)
        if not d:
            raise EOFError("marionette closed")
        return d

    def _recv(self):
        while b":" not in self.buf:
            self.buf += self._read()
        head, rest = self.buf.split(b":", 1)
        size = int(head)
        while len(rest) < size:
            rest += self._read()
        self.buf = rest[size:]
        return json.loads(rest[:size])

    def call(self, cmd, params=None):
        self.n += 1
        msg = json.dumps([0, self.n, cmd, params or {}]).encode()
        self.s.sendall(str(len(msg)).encode() + b":" + msg)
        while True:
            r = self._recv()
            if r[0] == 1 and r[1] == self.n:
                if r[2]:
                    raise RuntimeError(str(r[2])[:400])
                return r[3]

    def script(self, body, arg):
        return self.call("WebDriver:ExecuteScript", {
            "script": "return (async (args) => {" + body + "})(arguments[0]);",
            "args": [arg],
        })["value"]


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def parse_user_js(text):
    out = {}
    for line in text.splitlines():
        m = re.match(r'user_pref\("([^"]+)", (.*)\);$', line.strip())
        if m:
            out[m.group(1)] = json.loads(m.group(2))
    return out


def parse_perms(text):
    rows = []
    for line in text.splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        rows.append(tuple(line.split("\t")))
    return rows


SESSION_JS = r"""
const P = Services.prefs, D = P.getDefaultBranch("");
const eff = {}, noDefault = [];
for (const k of args.keys) {
  const t = P.getPrefType(k);
  eff[k] = t == 32 ? P.getStringPref(k) : t == 128 ? P.getBoolPref(k) : t == 64 ? P.getIntPref(k) : null;
  let ok = false;
  try { if (t == 128) D.getBoolPref(k); else if (t == 64) D.getIntPref(k); else D.getStringPref(k); ok = true; } catch (e) {}
  if (!ok) noDefault.push(k);
}
const mk = o => Services.scriptSecurityManager.createContentPrincipalFromOrigin(o);
for (const o of args.addPerms) Services.perms.addFromPrincipal(mk(o), "persist-data-on-shutdown", 1);
const perms = Services.perms.all.map(p => [p.type, p.principal.origin, p.capability]);
const builtin = await (await fetch("resource://app/defaults/permissions")).text();
for (const h of args.cookieHosts)
  Services.cookies.add(h, "/", "lwtest", "v", true, false, false, Date.now() + 86400000, {}, 0, Ci.nsICookie.SCHEME_HTTPS, false);
for (const u of args.historyUrls)
  await PlacesUtils.history.insert({ url: u, visits: [{ date: new Date() }] });
return { eff, noDefault, perms, builtin, cookiesSeeded: Services.cookies.cookies.map(c => c.host),
         cfgUrl: P.getStringPref("autoadmin.global_config_url", "") };
"""


def run_session(name, pkg, work, user_js, args, profile_dir, overrides):
    home = os.path.join(work, name, "home")
    prof = os.path.join(home, profile_dir)
    os.makedirs(prof)
    for o in overrides:
        path = os.path.join(home, o["path"])
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(o["text"])
    port = free_port()
    with open(os.path.join(prof, "user.js"), "w") as f:
        f.write(user_js)
        f.write('\nuser_pref("marionette.port", %d);\n' % port)
        f.write('user_pref("remote.prefs.recommended", false);\n')
        f.write('user_pref("network.proxy.type", 1);\n')
        f.write('user_pref("network.proxy.http", "127.0.0.1");\nuser_pref("network.proxy.http_port", 9);\n')
        f.write('user_pref("network.proxy.ssl", "127.0.0.1");\nuser_pref("network.proxy.ssl_port", 9);\n')
    env = {k: v for k, v in os.environ.items() if k not in ("DISPLAY", "WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS")}
    env.update(HOME=home, XDG_CONFIG_HOME=home + "/.config", XDG_CACHE_HOME=home + "/.cache",
               XDG_DATA_HOME=home + "/.local/share", MOZ_HEADLESS="1", MOZ_DISABLE_CONTENT_SANDBOX="1",
               MOZ_CRASHREPORTER_DISABLE="1", MOZ_DISABLE_AUTO_SAFE_MODE="1")
    env.pop("XDG_RUNTIME_DIR", None)
    log = open(os.path.join(work, name, "browser.log"), "w")
    proc = subprocess.Popen(
        [os.path.join(pkg, "bin", "librewolf"), "--headless", "--no-remote", "--marionette",
         "--remote-allow-system-access", "--profile", prof, "about:blank"],
        env=env, stdout=log, stderr=log, start_new_session=True)
    try:
        m = Marionette(port)
        m.call("WebDriver:NewSession", {"capabilities": {}})
        m.call("Marionette:SetContext", {"value": "chrome"})
        res = m.script(SESSION_JS, args)
        try:
            m.call("Marionette:Quit", {"flags": ["eAttemptQuit"]})
        except (EOFError, OSError):
            pass
        proc.wait(timeout=90)
    finally:
        if proc.poll() is None:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.wait()
        log.close()
    res["after"] = read_after(prof)
    res["home"] = home
    return res


def read_after(prof):
    def q(db, sql):
        con = sqlite3.connect(os.path.join(prof, db))
        try:
            return [r[0] for r in con.execute(sql)]
        finally:
            con.close()
    return {
        "cookies": q("cookies.sqlite", "select host from moz_cookies where name='lwtest'"),
        "visits": q("places.sqlite",
                    "select p.url from moz_historyvisits v join moz_places p on p.id=v.place_id"),
    }


def cfg_calls(text, fn):
    out = {}
    for k, raw in re.findall(r'^\s*' + fn + r'\("([^"]+)", (.+?)\);\s*(?://.*)?$', text, re.M):
        try:
            out[k] = json.loads(raw)
        except ValueError:
            out[k] = raw
    return out


def overrides_blocks(text):
    return {name: cfg_calls(body, "pref")
            for name, body in re.findall(r'^if \(profile === "([^"]+)"\) \{\n(.*?)^\}', text, re.M | re.S)}


def effective_cfg(mozcfg, block):
    eff = cfg_calls(mozcfg, "pref")
    eff.update(block)
    eff.update(cfg_calls(mozcfg, "lockPref"))
    return eff


def static_conflicts(user_prefs, overrides):
    return sorted("%s (user.js %s, startup cfg %s)" % (k, str(v)[:40], str(overrides[k])[:40])
                  for k, v in user_prefs.items() if k in overrides and overrides[k] != v)


def first_bool_cfg_pref(cfg_text, exclude):
    for k, v in re.findall(r'^pref\("([^"]+)", (true|false)\);', cfg_text, re.M):
        if k not in exclude:
            return k, v == "true"
    raise SystemExit("no boolean pref() line found in mozilla.cfg")


def main():
    pkg, perms_file, js_default, js_privacy, layout_file = sys.argv[1:6]
    work = tempfile.mkdtemp(prefix="lw-runtime-")
    try:
        mozcfg = open(os.path.join(pkg, "lib", "librewolf", "mozilla.cfg")).read()
        text = {"default": open(js_default).read(), "privacy": open(js_privacy).read()}
        user = {n: parse_user_js(t) for n, t in text.items()}
        perm_rows = parse_perms(open(perms_file).read())
        persist = [r[3] for r in perm_rows if r[1] == "persist-data-on-shutdown"]
        hosts = [urlparse(o).hostname for o in persist]
        allowed_hosts = hosts + ["sub." + h for h in hosts]
        cookie_hosts = allowed_hosts + UNLISTED_HOSTS
        history = ["https://%s/page" % h for h in (hosts[:1] + UNLISTED_HOSTS)]

        layout = json.load(open(layout_file))
        ovr = layout["overrides"]
        report("static: exactly one librewolf.overrides.cfg is generated",
               [] if len(ovr) == 1 else ["found %d: %r" % (len(ovr), [o["path"] for o in ovr])])
        ovr_text = ovr[0]["text"] if ovr else ""
        markers = re.findall(r'getPref\("([^"]+)"\)', ovr_text)
        marker = markers[0] if len(markers) == 1 else None
        blocks = overrides_blocks(ovr_text)
        problems = [] if marker else ["no single getPref() profile marker: %r" % markers]
        if marker:
            problems += ["%s user.js marker %r has no overrides block" % (n, user[n].get(marker))
                         for n in ("default", "privacy") if user[n].get(marker) not in blocks]
        report("static: each profile's user.js marker selects its own librewolf.overrides.cfg block", problems)
        EXEMPT_NO_DEFAULT.update(markers)

        def block_of(n):
            return blocks.get(user[n].get(marker), {}) if marker else {}

        for n in ("default", "privacy"):
            report("static: %s user.js has no pref that mozilla.cfg pref()/lockPref() overrides with another value "
                   "after librewolf.overrides.cfg" % n,
                   static_conflicts(user[n], effective_cfg(mozcfg, block_of(n))))

        problems = []
        if not perm_rows:
            problems.append("no rows")
        bad = [r for r in perm_rows if len(r) != 4 or r[0] != "origin" or r[2] != "1" or not re.match(r"^(https://[^/\s]+|about:\w+)$", r[3])]
        problems += ["malformed row %r" % (r,) for r in bad]
        problems += (["duplicate rows"] if len(set(perm_rows)) != len(perm_rows) else [])
        problems += (["no persist-data-on-shutdown rows"] if not persist else [])
        problems += ["persist origin not https://host: %s" % o for o in persist if not re.match(r"^https://[^/\s]+$", o)]
        report("static: allow-list file is well-formed (TAB rows, unique, https origins, >=1 persist row)", problems)

        flip_key, flip_val = first_bool_cfg_pref(mozcfg, set(user["privacy"]))
        control_js = text["privacy"] + 'user_pref("%s", %s);\nuser_pref("%s", true);\n' % (
            flip_key, "false" if flip_val else "true", BOGUS)
        ctrl_user = dict(user["privacy"])
        ctrl_user[flip_key] = (not flip_val)
        ctrl_user[BOGUS] = True

        sc = static_conflicts(ctrl_user, effective_cfg(mozcfg, block_of("privacy")))
        report("control: static override check flags an injected conflicting pref (%s)" % flip_key,
               [] if any(x.startswith(flip_key + " ") for x in sc) and not any(x.startswith(BOGUS) for x in sc)
               else ["injected %s not flagged (or bogus key flagged): %r" % (flip_key, sc)])

        sessions = {}
        pdir = layout["profileDir"]
        for name, prof, js, u, add, o in (("default", "default", text["default"], user["default"], [], ovr),
                                          ("privacy", "privacy", text["privacy"], user["privacy"], [], ovr),
                                          ("control", "privacy", control_js, ctrl_user, persist, ovr),
                                          ("no-overrides", "privacy", text["privacy"], user["privacy"], [], [])):
            sessions[name] = run_session(name, pkg, work, js, {
                "keys": list(u), "addPerms": add, "cookieHosts": cookie_hosts, "historyUrls": history},
                pdir[prof], o)

        def parity(name, u):
            s = sessions[name]
            return ["%s: want %s got %s" % (k, str(v)[:50], str(s["eff"][k])[:50])
                    for k, v in u.items() if k not in NOT_COMPARED and s["eff"][k] != v]

        def unknown(name, u):
            return [k for k in sessions[name]["noDefault"]
                    if k not in EXEMPT_NO_DEFAULT and not k.startswith(EXEMPT_PREFIX)]

        for n in ("default", "privacy"):
            report("runtime: %s effective prefs equal the generated user.js (nothing overridden at startup)" % n,
                   parity(n, user[n]))
            report("runtime: %s every pref exists in the shipped LibreWolf build" % n, unknown(n, user[n]))

        pv = sessions["privacy"]
        want_url = "file://" + os.path.join(pv["home"], ovr[0]["path"]) if ovr else "<none generated>"
        report("runtime: LibreWolf loads librewolf.overrides.cfg from the path home-manager writes it to",
               [] if pv["cfgUrl"] == want_url else ["browser reads %r, home.file writes %r" % (pv["cfgUrl"], want_url)])

        lost = sorted(x.split(":")[0] for x in parity("no-overrides", user["privacy"]))
        model = sorted(x.split(" ")[0] for x in static_conflicts(user["privacy"], effective_cfg(mozcfg, {})))
        report("control: without librewolf.overrides.cfg the privacy prefs lost at runtime are exactly those the "
               "static mozilla.cfg model predicts (%d)" % len(model),
               [] if lost == model else ["runtime lost %r, static model %r" % (lost, model)])

        c = parity("control", ctrl_user)
        report("control: parity check flags exactly the pref mozilla.cfg overrides (%s)" % flip_key,
               [] if any(x.startswith(flip_key + ":") for x in c) else ["injected override %s not flagged" % flip_key])
        cu = unknown("control", ctrl_user)
        report("control: validity check flags an injected unknown pref and nothing exempt",
               [] if cu == [BOGUS] else ["flagged %r, expected only the bogus key" % cu])

        have = {(t, o) for t, o, _ in pv["perms"]}
        report("runtime: privacy allow-list origins are loaded as persist-data-on-shutdown permissions",
               ["missing %s" % o for o in persist if ("persist-data-on-shutdown", o) not in have])
        shipped = parse_perms(pv["builtin"])
        listed = {r[1:] for r in perm_rows}
        report("runtime: privacy allow-list file carries every shipped default permission",
               ["file lacks %r" % (r[1:],) for r in shipped if r[1:] not in listed]
               + (["shipped defaults empty"] if not shipped else []))
        report("runtime: privacy shipped default permissions still active (uitour/install survive the defaultsUrl swap)",
               ["not active: %s %s" % (r[1], r[3]) for r in shipped if (r[1], r[3]) not in have])

        def survivors(name):
            a = sessions[name]["after"]
            return a

        a = survivors("privacy")
        seeded = set(sessions["privacy"]["cookiesSeeded"])
        report("runtime: privacy cookies were seeded (non-vacuous)",
               [] if all(h in seeded for h in cookie_hosts) else ["seeding incomplete"])
        report("runtime: privacy exit wipe clears unlisted cookies and all history",
               ["cookie survived: %s" % h for h in UNLISTED_HOSTS if h in a["cookies"]]
               + ["history survived: %s" % u for u in a["visits"] if urlparse(u).hostname in UNLISTED_HOSTS]
               + (["history survived: %d visits" % len(a["visits"])] if a["visits"] else []))
        report("runtime: privacy exit wipe keeps allow-listed origins and their subdomains",
               ["cookie wiped: %s" % h for h in allowed_hosts if h not in a["cookies"]])

        ca = survivors("control")
        report("control: with the allow-list added as runtime permissions the wipe keeps listed cookies and clears unlisted",
               ["wiped: %s" % h for h in allowed_hosts if h not in ca["cookies"]]
               + ["survived: %s" % h for h in UNLISTED_HOSTS if h in ca["cookies"]]
               + (["history survived"] if ca["visits"] else []))

        da = survivors("default")
        report("runtime: default profile wipes nothing on exit (cookies, history)",
               ["cookie wiped: %s" % h for h in cookie_hosts if h not in da["cookies"]]
               + ["history wiped: %s" % u for u in history if u not in da["visits"]])
    finally:
        shutil.rmtree(work, ignore_errors=True)
    for label, res in RESULTS:
        print("%s\t%s" % (label, res))


if __name__ == "__main__":
    main()
