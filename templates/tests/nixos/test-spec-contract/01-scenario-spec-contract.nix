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
    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/toplevel/nix-nixos.nix")
    (src + "/modules/common/themes/catppuccin.nix")
    (src + "/modules/nixos/toplevel/common-configuration-nixos.nix")

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
    (src + "/modules/common/programs/fastfetch.nix")
    (src + "/modules/nixos/programs/claude-desktop.nix")
    (src + "/modules/nixos/programs/nix-alien.nix")
    (src + "/modules/nixos/programs/nix-ld.nix")

    # Services whose enable options specs override
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/common/services/tailscale.nix")
    (src + "/modules/nixos/toplevel/bluetooth.nix")
    (src + "/modules/common/services/localsend.nix")
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

    # krit specializations
    (src + "/users/krit/nixos/specializations/entertainment.nix")
    (src + "/users/krit/nixos/specializations/home.nix")
    (src + "/users/krit/nixos/specializations/school.nix")
  ];

  config = (denix.lib.configurations {
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
      inputs = flake.inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (src + "/templates/tests/nixos/test-spec-contract/shared/host-spec-contract.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  }).spec-contract.config;

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

  checkAdded = name: baseLst: specLst:
    if baseLst != [ ] then "FAIL: ${name}: base host already has entries, check is vacuous"
    else if specLst == [ ] then "FAIL: ${name}: expected non-empty list, got []"
    else "ok";

  hasPkg = pkglist: pname: builtins.any (p: (p.pname or p.name or "") == pname) pkglist;
  checkPkgInList = name: basePkgs: pkglist: pname:
    if hasPkg basePkgs pname then "FAIL: ${name}: '${pname}' already in base home.packages, check is vacuous"
    else if hasPkg pkglist pname then "ok"
    else "FAIL: ${name}: package '${pname}' not found in home.packages";

  baseHm = config.home-manager.users.krit;
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
  check-guest-hyprlock-disabled =
    off "guest" (c: c.myconfig.services.hyprlock.enable) "hyprlock.enable" false;
  check-guest-hypridle-disabled =
    off "guest" (c: c.myconfig.services.hypridle.enable) "hypridle.enable" false;
  check-guest-swaync-disabled =
    off "guest" (c: c.myconfig.services.swaync.enable) "swaync.enable" false;
  check-guest-welcome-desktop =
    let
      path = "xdg/autostart/guest-welcome.desktop";
      text = (spec "guest").environment.etc.${path}.text;
    in
    if config.environment.etc ? ${path} then "FAIL: base host already has ${path}, check is vacuous"
    else if !(lib.strings.hasInfix "/bin/guest-welcome\n" text) then "FAIL: guest autostart Exec does not end in /bin/guest-welcome"
    else checkContains "guest autostart OnlyShowIn" text "OnlyShowIn=XFCE;";

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
  check-securetravel-bluetooth-disabled =
    off "secure-travel" (c: c.myconfig.bluetooth.enable) "bluetooth.enable" false;
  check-securetravel-hyprland-disabled =
    off "secure-travel" (c: c.myconfig.programs.hyprland.enable) "hyprland.enable" false;
  check-securetravel-tailscale-disabled =
    off "secure-travel" (c: c.myconfig.services.tailscale.enable) "tailscale.enable" false;
  check-securetravel-nix-ld-disabled =
    off "secure-travel" (c: c.myconfig.programs.nix-ld.enable) "nix-ld.enable" false;
  check-securetravel-gnome-enabled =
    off "secure-travel" (c: c.myconfig.programs.gnome.enable) "gnome.enable" true;
  check-securetravel-killswitch-exists =
    checkAdded "secure-travel NM dispatcherScripts"
      config.networking.networkmanager.dispatcherScripts
      (spec "secure-travel").networking.networkmanager.dispatcherScripts;

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
