# Specialization contract scenario.
# Evaluates a fake host with only the modules that specializations touch, then
# reads each specialization's config to verify lib.mkForce overrides landed.
#
# All checks return "ok" or "FAIL: <detail>" for use with nix eval --raw.
#
# Usage:
#   nix eval --raw --impure --file this.nix --attr check-<name>
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    # x86_64 platform override + home-manager base + stylix stub
    (src + "/templates/tests/nixos/test-spec-contract/shared/nixos-extra-x86_64")

    # Core infrastructure
    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/toplevel/nix-nixos.nix")
    (src + "/modules/common/themes/catppuccin.nix")
    (src + "/modules/nixos/toplevel/common-configuration-nixos.nix")
    (src + "/modules/nixos/toplevel/user-nixos.nix")

    # WM enable options - specs reference myconfig.programs.*.enable on all of these
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/toplevel/gnome.nix")
    (src + "/modules/nixos/toplevel/kde.nix")
    (src + "/modules/nixos/toplevel/cosmic.nix")

    # Hyprland DE modules (needed for monitors/execOnce/windowRules options)
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")

    # Waybar (home spec forces waybar-hyprland.waybarWorkspaceIcons)
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")

    # Niri DE modules (school/home specs reference niri.execOnce, niri.outputs)
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")

    # Mango DE modules (school/home specs reference mango.execOnce, mango.monitors)
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")

    # Gnome DE modules (secure-travel forces gnome.enable = true)
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-main.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-binds.nix")

    # KDE DE modules (entertainment forces kde.enable = true; plasma-manager HM options)
    (src + "/modules/nixos/programs/de-wm/kde/kde-main.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-desktop.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-files.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-inputs.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-krunner.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-panels.nix")

    # Custom shells (enabled in host so guest/safe-mode/secure-travel overrides are real)
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Programs whose enable options specs override
    (src + "/modules/common/programs/claude-code.nix")
    (src + "/modules/common/programs/codex.nix")
    (src + "/modules/common/programs/agent-reach.nix")
    (src + "/modules/common/programs/headroom.nix")
    (src + "/modules/common/programs/herdr.nix")
    (src + "/modules/common/programs/zen-browser.nix")
    (src + "/users/krit/common/programs/claude-code-wrappers.nix")
    (src + "/modules/common/programs/fastfetch.nix")
    (src + "/modules/nixos/programs/claude-desktop.nix")
    (src + "/modules/nixos/programs/google-antigravity.nix")
    (src + "/modules/nixos/programs/nix-alien.nix")
    (src + "/modules/nixos/programs/nix-ld.nix")

    # Services whose enable options specs override
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/power/coffee.nix")
    (src + "/modules/nixos/services/airplane.nix")
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/common/services/tailscale.nix")
    (src + "/modules/nixos/toplevel/bluetooth.nix")
    (src + "/modules/nixos/services/localsend.nix")
    (src + "/users/krit/nixos/services/nas/smb.nix")
    (src + "/users/krit/nixos/services/nas/opencloud.nix")
    (src + "/users/krit/nixos/services/nas/ssh.nix")
    (src + "/users/krit/nixos/services/nas/borg-backup/borg-backup-desktop.nix")
    (src + "/users/krit/nixos/services/nas/borg-backup/borg-backup-laptop.nix")

    # Shell modules (used by safe-mode to force bash and by school initExtra)
    (src + "/modules/common/programs/shells/bash.nix")
    (src + "/modules/common/programs/shells/fish.nix")
    (src + "/modules/common/programs/shells/zsh.nix")

    # Global specializations
    (src + "/modules/nixos/specializations/deep-focus.nix")
    (src + "/modules/nixos/specializations/guest.nix")
    (src + "/modules/nixos/specializations/safe-mode.nix")
    (src + "/modules/nixos/specializations/secure-travel.nix")

    # Minimal user infrastructure
    (src + "/users/krit/nixos/shared/home/home-base.nix")
    (src + "/users/krit/nixos/shared/system/default-user.nix")
    (src + "/users/krit/nixos/shared/system/virtualisation.nix")
    (src + "/users/krit/nixos/shared/system/git-ssh-signing.nix")

    # krit specializations
    (src + "/users/krit/nixos/specializations/entertainment.nix")
    (src + "/users/krit/nixos/specializations/home.nix")
    (src + "/users/krit/nixos/specializations/school.nix")
  ];

  host = (denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inherit (flake) inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (src + "/templates/tests/nixos/test-spec-contract/shared/host-spec-contract.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  }).spec-contract;
  inherit (host) config;
  swayncOffBase = (host.extendModules { modules = [{ myconfig.services.swaync.enable = lib.mkOverride 60 false; }]; }).config;

  # spec name → full NixOS config with that specialization applied
  spec = name: config.specialisation.${name}.configuration;
  # specHm name → home-manager krit config within that specialization
  specHm = name: (spec name).home-manager.users.krit;

  checkOverride = name: baseVal: specVal: expected:
    if baseVal == expected then "FAIL: ${name}: base host already ${lib.boolToString expected}, override is vacuous"
    else checkBool name specVal expected;

  checkBool = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${if expected then "true" else "false"}, got ${if actual then "true" else "false"}";

  checkStr = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected '${expected}', got '${actual}'";

  checkContains = name: str: substr:
    if lib.strings.hasInfix substr str then "ok"
    else "FAIL: ${name}: expected to contain '${substr}'";

  hasPkg = pkglist: pname: builtins.any (p: (p.pname or p.name or "") == pname) pkglist;
  checkPkgInList = name: basePkgs: pkglist: pname:
    if hasPkg basePkgs pname then "FAIL: ${name}: '${pname}' already in base home.packages, check is vacuous"
    else if hasPkg pkglist pname then "ok"
    else "FAIL: ${name}: package '${pname}' not found in home.packages";

  baseHm = config.home-manager.users.krit;
  dndIn = wm: get:
    let
      has = c: builtins.any (lib.hasInfix "swaync-client -dn") (get c);
    in
    if has config then "FAIL: base ${wm} execOnce already enables DND, check is vacuous"
    else if has (spec "deep-focus") then "ok"
    else "FAIL: deep-focus ${wm} execOnce lacks 'swaync-client -dn': ${builtins.toJSON (get (spec "deep-focus"))}";
  off = sp: path: name: expected: checkOverride "${sp}.${name}" (path config) (path (spec sp)) expected;
in
{
  # ── guest ────────────────────────────────────────────────────────────────────
  check-guest-hyprland-disabled =
    off "guest" (c: c.myconfig.programs.hyprland.enable) "hyprland.enable" false;
  check-guest-stylix-disabled =
    off "guest" (c: c.myconfig.stylix.enable) "stylix.enable" false;
  check-guest-bluetooth-disabled =
    off "guest" (c: c.myconfig.bluetooth.enable) "bluetooth.enable" false;
  check-guest-hypridle-disabled =
    off "guest" (c: c.myconfig.services.hypridle.enable) "hypridle.enable" false;
  check-guest-coffee-disabled =
    off "guest" (c: c.myconfig.services.coffee.enable) "coffee.enable" false;
  check-guest-swaync-disabled =
    off "guest" (c: c.myconfig.services.swaync.enable) "swaync.enable" false;
  check-guest-claude-code-disabled =
    off "guest" (c: c.myconfig.programs.claude-code.enable) "claude-code.enable" false;
  check-guest-claude-desktop-disabled =
    off "guest" (c: c.myconfig.programs.claude-desktop.enable) "claude-desktop.enable" false;
  check-guest-codex-disabled =
    off "guest" (c: c.myconfig.programs.codex.enable) "codex.enable" false;
  check-guest-herdr-disabled =
    off "guest" (c: c.myconfig.programs.herdr.enable) "herdr.enable" false;
  check-guest-headroom-disabled =
    off "guest" (c: c.myconfig.programs.headroom.enable) "headroom.enable" false;
  check-guest-headroom-unit-absent =
    off "guest" (c: c.home-manager.users.krit.systemd.user.services ? headroom-proxy) "headroom-proxy unit present" false;
  check-guest-claude-wrappers-disabled =
    off "guest" (c: c.myconfig.krit.programs.claude-code-wrappers.enable) "claude-code-wrappers.enable" false;
  check-guest-tailscale-disabled =
    off "guest" (c: c.myconfig.services.tailscale.enable) "tailscale.enable" false;
  check-guest-tailscale-service-off =
    off "guest" (c: c.services.tailscale.enable) "services.tailscale.enable" false;
  check-guest-localsend-disabled =
    off "guest" (c: c.myconfig.services.localsend.enable) "localsend.enable" false;
  check-guest-openssh-disabled =
    off "guest" (c: c.services.openssh.enable) "openssh.enable" false;
  check-guest-avahi-disabled =
    off "guest" (c: c.services.avahi.enable) "avahi.enable" false;
  check-guest-docker-disabled =
    off "guest" (c: c.virtualisation.docker.enable) "docker.enable" false;
  check-guest-podman-disabled =
    off "guest" (c: c.virtualisation.podman.enable) "podman.enable" false;
  check-guest-allowed-users =
    if config.nix.settings.allowed-users == [ "krit" ] then "FAIL: base allowed-users already [ krit ], check is vacuous"
    else if (spec "guest").nix.settings.allowed-users == [ "krit" ] then "ok"
    else "FAIL: guest allowed-users is ${builtins.toJSON (spec "guest").nix.settings.allowed-users}, expected [ krit ] (the guest must not be a nix user)";
  check-guest-pat-token-mode =
    let mode = c: c.sops.secrets.github_fg_pat_token_nix.mode; in
    if mode config == "0400" then "FAIL: base PAT mode already 0400, check is vacuous"
    else checkStr "guest PAT secret mode" (mode (spec "guest")) "0400";
  check-guest-no-linger-persistence =
    let
      dirs = c: map (d: d.directory) c.environment.persistence."/persist".directories;
    in
    if !(builtins.elem "/var/lib/systemd/linger" (dirs config)) then "FAIL: base does not persist linger dir, check is vacuous"
    else if builtins.elem "/var/lib/systemd/linger" (dirs (spec "guest")) then "FAIL: guest still persists /var/lib/systemd/linger"
    else if !(builtins.elem "/etc/ssh" (dirs (spec "guest"))) then "FAIL: guest lost the other persisted directories"
    else "ok";
  check-guest-extra-groups =
    let g = (spec "guest").users.users.guest.extraGroups; in
    if lib.sort lib.lessThan g == [ "audio" "video" ] then "ok"
    else "FAIL: guest extraGroups is ${builtins.toJSON g}, expected audio and video only";
  check-guest-no-zenity-system-package =
    let
      has = c: hasPkg c.environment.systemPackages "zenity";
      welcome = (spec "guest").environment.etc."xdg/autostart/guest-welcome.desktop".text;
    in
    if has (spec "guest") then "FAIL: zenity in guest environment.systemPackages"
    else if !(lib.hasInfix "/bin/guest-welcome" welcome) then "FAIL: control: guest-welcome autostart missing, so the zenity-free systemPackages proves nothing"
    else "ok";
  check-guest-welcome-desktop =
    let
      path = "xdg/autostart/guest-welcome.desktop";
      text = (spec "guest").environment.etc.${path}.text;
    in
    if config.environment.etc ? ${path} then "FAIL: base host already has ${path}, check is vacuous"
    else if !(lib.strings.hasInfix "/bin/guest-welcome\n" text) then "FAIL: guest autostart Exec does not end in /bin/guest-welcome"
    else checkContains "guest autostart OnlyShowIn" text "OnlyShowIn=XFCE;";

  # ── deep-focus ───────────────────────────────────────────────────────────────
  check-deepfocus-swaync-enabled =
    if swayncOffBase.myconfig.services.swaync.enable then "FAIL: control: twin base still has swaync on"
    else checkBool "deep-focus.swaync.enable" swayncOffBase.specialisation.deep-focus.configuration.myconfig.services.swaync.enable true;
  check-deepfocus-hyprland-dnd =
    dndIn "hyprland" (c: c.myconfig.programs.hyprland.execOnce);
  check-deepfocus-niri-dnd =
    dndIn "niri" (c: c.myconfig.programs.niri.execOnce);
  check-deepfocus-mango-dnd =
    dndIn "mango" (c: c.myconfig.programs.mango.execOnce);
  check-deepfocus-mango-no-distractions =
    let
      lst = c: map lib.toLower c.myconfig.programs.mango.execOnce;
      bad = c: builtins.filter (e: lib.hasInfix "zapzap" e || lib.hasInfix "youtube" e) (lst c);
    in
    if bad config == [ ] then "FAIL: base mango execOnce has no zapzap/youtube, check is vacuous"
    else if bad (spec "deep-focus") != [ ] then "FAIL: deep-focus mango still starts: ${builtins.toJSON (bad (spec "deep-focus"))}"
    else if lst (spec "deep-focus") == [ ] then "FAIL: deep-focus mango execOnce is empty"
    else "ok";

  # ── safe-mode ────────────────────────────────────────────────────────────────
  check-safemode-stylix-disabled =
    off "safemode" (c: c.myconfig.stylix.enable) "stylix.enable" false;
  check-safemode-shell-bash =
    if config.myconfig.constants.shell == "bash" then "FAIL: base shell already bash, check is vacuous"
    else checkStr "safemode.constants.shell" (spec "safemode").myconfig.constants.shell "bash";
  check-safemode-terminal-xterm =
    if config.myconfig.constants.terminal.name == "xterm" then "FAIL: base terminal already xterm, check is vacuous"
    else checkStr "safemode.constants.terminal.name" (spec "safemode").myconfig.constants.terminal.name "xterm";
  check-safemode-hyprland-disabled =
    off "safemode" (c: c.myconfig.programs.hyprland.enable) "hyprland.enable" false;
  check-safemode-fastfetch-disabled =
    off "safemode" (c: c.myconfig.programs.fastfetch.enable) "fastfetch.enable" false;
  check-safemode-xserver-enabled =
    if config.services.xserver.enable then "FAIL: base xserver already enabled, check is vacuous"
    else checkBool "safemode.xserver.enable" (spec "safemode").services.xserver.enable true;
  check-safemode-tag =
    if builtins.elem "safemode-tty" config.system.nixos.tags then "FAIL: base already tagged safemode-tty, check is vacuous"
    else checkBool "safemode tag" (builtins.elem "safemode-tty" (spec "safemode").system.nixos.tags) true;
  check-safemode-icewm-enabled =
    off "safemode" (c: c.services.xserver.windowManager.icewm.enable) "icewm.enable" true;
  check-safemode-startx-enabled =
    off "safemode" (c: c.services.xserver.displayManager.startx.enable) "startx.enable" true;
  check-safemode-xinitrc-has-icewm =
    checkContains "safemode .xinitrc"
      (specHm "safemode").home.file.".xinitrc".text
      "icewm-session";
  check-safemode-alias-start-icewm =
    if baseHm.home.shellAliases ? "start-icewm" then "FAIL: base host already has start-icewm alias, check is vacuous"
    else
      checkStr "safemode.shellAliases.start-icewm"
        ((specHm "safemode").home.shellAliases."start-icewm" or "MISSING")
        "startx";

  # ── secure-travel ─────────────────────────────────────────────────────────────
  check-securetravel-bluetooth-radio-off-at-boot =
    off "secure-travel" (c: c.hardware.bluetooth.powerOnBoot) "bluetooth.powerOnBoot" false;
  check-securetravel-bluetooth-available =
    let st = spec "secure-travel"; in
    if (spec "guest").hardware.bluetooth.enable then "FAIL: control: guest has bluetooth on, override mechanism not proven"
    else if !(st.hardware.bluetooth.enable && st.services.blueman.enable) then "FAIL: secure-travel bluetooth/blueman not enabled (headphones must work)"
    else "ok";
  check-securetravel-hyprland-disabled =
    off "secure-travel" (c: c.myconfig.programs.hyprland.enable) "hyprland.enable" false;
  check-securetravel-tailscale-enabled =
    let st = spec "secure-travel"; in
    if (spec "guest").myconfig.services.tailscale.enable then "FAIL: control: guest has tailscale on, override mechanism not proven"
    else if !(st.myconfig.services.tailscale.enable && st.services.tailscale.enable) then "FAIL: secure-travel tailscale is off (it is the VPN)"
    else "ok";
  check-securetravel-tailscale-no-open-firewall =
    off "secure-travel" (c: c.services.tailscale.openFirewall) "tailscale.openFirewall" false;
  check-securetravel-no-trusted-interfaces =
    if config.networking.firewall.trustedInterfaces == [ "lo" ] then "FAIL: base trustedInterfaces already [ lo ], check is vacuous"
    else checkBool "secure-travel trustedInterfaces == [ lo ]" ((spec "secure-travel").networking.firewall.trustedInterfaces == [ "lo" ]) true;
  check-securetravel-localsend-disabled =
    off "secure-travel" (c: c.myconfig.services.localsend.enable) "localsend.enable" false;
  check-securetravel-coffee-disabled =
    off "secure-travel" (c: c.myconfig.services.coffee.enable) "coffee.enable" false;
  check-securetravel-nix-ld-disabled =
    off "secure-travel" (c: c.myconfig.programs.nix-ld.enable) "nix-ld.enable" false;
  check-securetravel-claude-code-disabled =
    off "secure-travel" (c: c.myconfig.programs.claude-code.enable) "claude-code.enable" false;
  check-securetravel-claude-desktop-disabled =
    off "secure-travel" (c: c.myconfig.programs.claude-desktop.enable) "claude-desktop.enable" false;
  check-securetravel-codex-disabled =
    off "secure-travel" (c: c.myconfig.programs.codex.enable) "codex.enable" false;
  check-securetravel-herdr-disabled =
    off "secure-travel" (c: c.myconfig.programs.herdr.enable) "herdr.enable" false;
  check-securetravel-headroom-disabled =
    off "secure-travel" (c: c.myconfig.programs.headroom.enable) "headroom.enable" false;
  check-securetravel-headroom-unit-absent =
    off "secure-travel" (c: c.home-manager.users.krit.systemd.user.services ? headroom-proxy) "headroom-proxy unit present" false;
  check-securetravel-claude-wrappers-disabled =
    off "secure-travel" (c: c.myconfig.krit.programs.claude-code-wrappers.enable) "claude-code-wrappers.enable" false;
  check-securetravel-zen-disabled =
    off "secure-travel" (c: c.myconfig.programs.zen.browser.enable) "zen.browser.enable" false;
  check-securetravel-browser-constant =
    if config.myconfig.constants.browser == "librewolf" then "FAIL: base browser already librewolf, check is vacuous"
    else checkStr "secure-travel.constants.browser" (spec "secure-travel").myconfig.constants.browser "librewolf";
  check-securetravel-gnome-enabled =
    off "secure-travel" (c: c.myconfig.programs.gnome.enable) "gnome.enable" true;
  check-securetravel-exitnode-warn-unit =
    let
      u = c: c.home-manager.users.krit.systemd.user;
      st = u (spec "secure-travel");
    in
    if (u config).services ? secure-travel-exitnode-warn then "FAIL: base already has the exit node warn unit, check is vacuous"
    else if !(st.services ? secure-travel-exitnode-warn && st.timers ? secure-travel-exitnode-warn) then "FAIL: user service/timer secure-travel-exitnode-warn missing"
    else if st.timers.secure-travel-exitnode-warn.Timer.OnActiveSec != "45s" || st.timers.secure-travel-exitnode-warn.Timer.OnUnitActiveSec != "2min" then "FAIL: timer cadence is not 45s/2min"
    else "ok";
  check-securetravel-trayscale-installed =
    let
      names = c: map (p: p.pname or p.name or "") c.home-manager.users.krit.home.packages;
    in
    if !(builtins.elem "trayscale" (names (spec "secure-travel"))) then "FAIL: trayscale missing from secure-travel krit home.packages"
    else "ok";
  check-securetravel-no-dispatcher-killswitch =
    let st = spec "secure-travel"; in
    if st.networking.networkmanager.wifi.macAddress != "random" then "FAIL: control: secure-travel NetworkManager settings not evaluated"
    else if st.networking.networkmanager.dispatcherScripts == [ ] then "ok"
    else "FAIL: secure-travel still installs a root NM dispatcher script";

  # ── entertainment ─────────────────────────────────────────────────────────────
  check-entertainment-kde-enabled =
    off "entertainment" (c: c.myconfig.programs.kde.enable) "kde.enable" true;
  check-entertainment-hyprland-disabled =
    off "entertainment" (c: c.myconfig.programs.hyprland.enable) "hyprland.enable" false;

  # ── school ────────────────────────────────────────────────────────────────────
  check-school-browser-constant =
    if config.myconfig.constants.browser == "brave-school" then "FAIL: base browser already brave-school, check is vacuous"
    else checkStr "school.constants.browser" (spec "school").myconfig.constants.browser "brave-school";
  check-school-editor-constant =
    if config.myconfig.constants.editor == "nvim" then "FAIL: base editor already nvim, check is vacuous"
    else checkStr "school.constants.editor" (spec "school").myconfig.constants.editor "nvim";
  check-school-setup-script =
    checkPkgInList "school home.packages" baseHm.home.packages (specHm "school").home.packages "school-distrobox-setup";
  check-school-check-script =
    checkPkgInList "school home.packages" baseHm.home.packages (specHm "school").home.packages "school-distrobox-check";
  check-school-clear-script =
    checkPkgInList "school home.packages" baseHm.home.packages (specHm "school").home.packages "school-distrobox-clear";

  # ── home ──────────────────────────────────────────────────────────────────────
  check-home-monitors =
    let
      ms = (spec "home").myconfig.programs.hyprland.monitors;
      bad = builtins.filter (m: (m.output or "") == "" || (m.mode or "") == "") ms;
    in
    if ms == config.myconfig.programs.hyprland.monitors then "FAIL: home spec monitors equal base host monitors, spec forces nothing"
    else if ms == [ ] then "FAIL: home spec sets no monitors"
    else if bad != [ ] then "FAIL: home spec has ${toString (builtins.length bad)} monitor(s) without output/mode"
    else "ok";
}
