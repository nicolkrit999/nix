# LibreWolf Configuration Structure

This configuration uses a **Hierarchical Profile System** to balance strict privacy with daily usability. Instead of forcing one global configuration, it splits logic into a "Common Base" and "Specialized Profiles".

## 1. The Structure

- **`librewolf-common.nix`**: The foundation. It defines settings, extensions, and policies that apply to _all_ instances of LibreWolf.
- **`librewolf-profile-default.nix`**: The "Daily Driver". It inherits the common settings but overrides specific privacy constraints to ensure logins (SSO, OIDC, Cloudflare) and media (DRM) work.
- **`librewolf-profile-privacy.nix`**: The "Hardened" profile. It inherits common settings and applies stricter rules (e.g., erasing history on shutdown, strict blocking).

---

## 2. `librewolf-common.nix` (The Foundation)

This file acts as the **factory** for the browser. It does three critical things:

### A. Policy Injection (The Wrapper)

LibreWolf normally ignores some declarative configuration. We force it to listen by wrapping the binary.

- It creates a custom `policies.json` file at runtime.
- It defines a wrapper script (`MOZ_APP_DISTRIBUTION`) that points the browser to this policy file on startup.

### B. The "Unlocked" Policy

**Crucial Design Choice:** We removed the `Preferences` block from `policies.json`.

- **Why?** Settings defined in `policies.json` are **Locked** (Immutable). If we set `privacy.resistFingerprinting = true` here, the Default profile _could not_ turn it off.
- **The Fix:** We only put universal allowlists (Extensions, Cookies, Popups) in the Policy. All actual preferences are moved to `commonSettings` (User.js), which allows individual profiles to overwrite them.

### C. Common Settings (`commonSettings`)

It defines a set of "Junk Off" preferences that we want everywhere:

- Disables Telemetry & Pocket.
- Cleans up the UI (Vertical Tabs, Toolbars).
- Sets generic search engine configurations (Kagi, etc.).

---

## 3. `librewolf-profile-default.nix` (The Daily Driver)

This profile is designed to "Just Work" while keeping the "Junk Off" benefits of the common config. It enables authentication by explicitly **relaxing** specific constraints.

### How Authentication Works (SSO / Cloudflare / PocketID)

Modern logins (OIDC, Cloudflare Turnstile, Passkeys) break under strict privacy rules. This profile fixes them via:

1.  **Enabling Third-Party Contexts**

    ```nix
    "privacy.firstparty.isolate" = false;
    "network.cookie.cookieBehavior" = 0;
    ```

    - **Why:** When you are redirected to Cloudflare or a Login Provider, strict isolation treats it as a "New" unrelated visit, breaking the login chain. Disabling FPI allows the login cookie to persist across the redirect.

2.  **Enabling Credential APIs**

    ```nix
    "identity.fxaccounts.enabled" = true;
    "dom.credentialmanagement.enabled" = true;
    ```

    - **Why:** Even if you don't use Firefox Sync, the internal `navigator.credentials` API (used for Passkeys and some SSO tokens) relies on the Firefox Accounts subsystem being "active" in the code.

3.  **Disabling Fingerprint Spoofing**
    ```nix
    "privacy.resistFingerprinting" = false;
    ```

    - **Why:** Cloudflare and Banking sites check your time zone, screen size, and user agent. If LibreWolf lies about these (RFP), these security checks fail, and you get stuck in a "Verifying..." loop.

### Usability Features

- **Session Restore:** Remembers your open tabs (`browser.startup.page = 3`).
- **DRM:** Enables Widevine (`media.eme.enabled = true`) for Spotify/Netflix.
- **History/Cookies:** Does _not_ auto-delete data on shutdown.

---

## 4. How They Work Together (The Inheritance)

The logic relies on the Nix `//` (Update) operator.

```nix
settings = commonSettings // {
  "privacy.resistFingerprinting" = false;
};
```

1. **Step 1:** Nix loads `commonSettings` (where `resistFingerprinting` might be `true` or unset).
2. **Step 2:** The Profile loads and sees the override (`false`).
3. **Step 3:** Because these are **User Preferences** (User.js) and not **Policies** (policies.json), the browser respects the Profile's specific choice.

### Summary

- **Common:** Sets the baseline "Clean Browser".
- **Default Profile:** Takes the baseline -> Adds Compatibility & Auth support.
- **Privacy Profile:** Takes the baseline -> Adds Hardening & Amnesia.
