{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.hyprland";
  options =
    with delib;
    moduleOptions {
      monitors = listOfOption str [ ",preferred, auto,1" ];
      execOnce = listOfOption str [ ];
      monitorWorkspaces = listOfOption str [ ];
      windowRules = listOfOption str [ ];
      # bind entries use HM's new lua bind format — see hyprland-binds.nix.
      extraBinds = listOfOption attrs [ ];
      extraBindl = listOfOption attrs [ ];
      noHardwareCursors = boolOption false;
    };

  nixos.ifEnabled = {
    myconfig.stylix.targets.hyprland.enable = false;
  };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      term = myconfig.constants.terminal.name or "alacritty";

      # ── tiny string helpers ──────────────────────────────────────────────
      luaStr = s:
        let
          esc = builtins.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" "\\n" ] s;
        in
        "\"${esc}\"";

      trim = s:
        let m = builtins.match "^[[:space:]]*(.*[^[:space:]]|)[[:space:]]*$" s;
        in if m == null then "" else builtins.head m;

      # Split string on first occurrence of `sep` (a single char as regex char).
      splitFirst = sep: s:
        let m = builtins.match "([^${sep}]*)${sep}(.*)" s;
        in if m == null then [ s ] else m;

      # Is `s` numeric (int or float)? Used to decide whether to quote in lua.
      isNum = s:
        let m = builtins.match "-?[0-9]+(\\.[0-9]+)?" s;
        in m != null;

      luaValue = s: if isNum s then s else luaStr s;

      # ── exec-once → hl.on("hyprland.start", function() ... end) ─────────
      execOnceLua = items:
        if items == [ ] then ""
        else
          "hl.on(\"hyprland.start\", function()\n"
          + (lib.concatMapStrings
            (cmd: "  hl.exec_cmd(${luaStr cmd})\n")
            items)
          + "end)\n";

      # ── env "KEY,VAL"  →  hl.env("KEY", "VAL") ──────────────────────────
      envLua = items:
        lib.concatMapStrings
          (item:
            let p = splitFirst "," item; in
            if builtins.length p == 2 then
              "hl.env(${luaStr (trim (builtins.elemAt p 0))}, ${luaStr (trim (builtins.elemAt p 1))})\n"
            else "")
          items;

      # ── monitor "name,mode,position,scale[,key,val...]" → hl.monitor({...}) ──
      monitorLua = items:
        lib.concatMapStrings
          (item:
            let
              parts = map trim (lib.splitString "," item);
              n = builtins.length parts;
              output = if n > 0 then builtins.elemAt parts 0 else "";
              mode = if n > 1 then builtins.elemAt parts 1 else "preferred";
              position = if n > 2 then builtins.elemAt parts 2 else "auto";
              scaleRaw = if n > 3 then builtins.elemAt parts 3 else "1";
              extras = lib.drop 4 parts;
              # Pair up extras: k,v,k,v,... — emit as ", key = value"
              extraPairs = builtins.genList
                (i: { k = builtins.elemAt extras (i * 2); v = builtins.elemAt extras (i * 2 + 1); })
                (builtins.length extras / 2);
              extraLua = lib.concatMapStrings
                (p: ", ${p.k} = ${luaValue p.v}")
                extraPairs;
            in
            "hl.monitor({ output = ${luaStr output}, mode = ${luaStr mode}, position = ${luaStr position}, scale = ${luaValue scaleRaw}${extraLua} })\n")
          items;

      # ── bezier "name, x1, y1, x2, y2"  →  hl.curve("name", {type, points}) ──
      bezierLua = items:
        lib.concatMapStrings
          (item:
            let
              parts = map trim (lib.splitString "," item);
              name = builtins.elemAt parts 0;
              p1x = builtins.elemAt parts 1;
              p1y = builtins.elemAt parts 2;
              p2x = builtins.elemAt parts 3;
              p2y = builtins.elemAt parts 4;
            in
            "hl.curve(${luaStr name}, { type = \"bezier\", points = { { ${p1x}, ${p1y} }, { ${p2x}, ${p2y} } } })\n")
          items;

      # ── animation "leaf, on, speed, bezier[, style]" → hl.animation({...}) ──
      animationLua = items:
        lib.concatMapStrings
          (item:
            let
              parts = map trim (lib.splitString "," item);
              leaf = builtins.elemAt parts 0;
              enabled = builtins.elemAt parts 1;
              speed = builtins.elemAt parts 2;
              bezier = builtins.elemAt parts 3;
              style = if builtins.length parts >= 5 then builtins.elemAt parts 4 else null;
              enabledLua = if enabled == "1" || enabled == "true" then "true" else "false";
              styleLua = if style == null then "" else ", style = ${luaStr style}";
            in
            "hl.animation({ leaf = ${luaStr leaf}, enabled = ${enabledLua}, speed = ${speed}, bezier = ${luaStr bezier}${styleLua} })\n")
          items;

      # Hyprland's lua API uses snake_case for rule keys; hyprlang spells the
      # same flags as one word (`noborder`, `nofocus`, ...). Translate the
      # known one-word → snake_case names; pass anything else through.
      # Authoritative window-rule effect names — derived from Hyprland's
      # WINDOW_RULE_EFFECT_DESCS table (src/config/lua/bindings/
      # LuaBindingsInternal.hpp). Map legacy one-word hyprlang spellings to
      # the snake_case lua names. Anything not listed passes through verbatim.
      ruleKeyMap = {
        nofocus = "no_focus";
        nofollowmouse = "no_follow_mouse";
        noinitialfocus = "no_initial_focus";
        noanim = "no_anim";
        noshadow = "no_shadow";
        noblur = "no_blur";
        nodim = "no_dim";
        nomaxsize = "no_max_size";
        noshortcutsinhibit = "no_shortcuts_inhibit";
        noscreenshare = "no_screen_share";
        novrr = "no_vrr";
        nocloseFor = "no_close_for";
        noclosefor = "no_close_for";
        suppressevent = "suppress_event";
        bordersize = "border_size";
        bordercolor = "border_color";
        forcergbx = "force_rgbx";
        keepaspectratio = "keep_aspect_ratio";
        nearestneighbor = "nearest_neighbor";
        maxsize = "max_size";
        minsize = "min_size";
        focusonactivate = "focus_on_activate";
        idleinhibit = "idle_inhibit";
        persistentsize = "persistent_size";
        renderunfocused = "render_unfocused";
        scrollingwidth = "scrolling_width";
        scrollmouse = "scroll_mouse";
        scrolltouchpad = "scroll_touchpad";
        stayfocused = "stay_focused";
        syncfullscreen = "sync_fullscreen";
        confinepointer = "confine_pointer";
        dimaround = "dim_around";
        allowsinput = "allows_input";
        fullscreenstate = "fullscreen_state";
        roundingpower = "rounding_power";
        # `noborder` and `norounding` have no boolean equivalents in the lua
        # window_rule API — set the corresponding size knob to 0 instead.
        # Handled as special cases in windowRuleLua below.
      };
      renameRuleKey = k: ruleKeyMap.${k} or k;

      # Match-condition property names — derived from MATCH_PROP_STRINGS in
      # src/desktop/rule/Rule.cpp. The lua match keys are NOT the same as
      # the rule-effect keys: e.g. `float` (not `floating`), `pin` (not
      # `pinned`). `fullscreen` is correct as-is.
      matchKeyMap = {
        floating = "float";
        pinned = "pin";
        initialclass = "initial_class";
        initialtitle = "initial_title";
      };
      renameMatchKey = k: matchKeyMap.${k} or k;

      # Workspace rule field names — derived from WORKSPACE_RULE_FIELDS.
      wsRuleKeyMap = {
        gapsin = "gaps_in";
        gapsout = "gaps_out";
        floatgaps = "float_gaps";
        bordersize = "border_size";
        noborder = "no_border";
        norounding = "no_rounding";
        noshadow = "no_shadow";
        oncreatedempty = "on_created_empty";
        defaultname = "default_name";
      };
      renameWsRuleKey = k: wsRuleKeyMap.${k} or k;

      # ── window rules (legacy hyprlang v2: "RULE, COND[, COND...]") ──
      # First token is the rule (possibly "key value", e.g. "size 80% 80%").
      # Remaining tokens are conditions: either "key:value" or bare flag.
      windowRuleLua = items:
        lib.concatMapStrings
          (item:
            let
              parts = map trim (lib.splitString "," item);
              ruleTok = builtins.elemAt parts 0;
              condToks = lib.drop 1 parts;
              # Rule: split on first space → key, rest is value (kept verbatim).
              rkv = splitFirst " " ruleTok;
              ruleKeyRaw = lib.toLower (if builtins.length rkv >= 1 then builtins.elemAt rkv 0 else ruleTok);
              ruleKey = renameRuleKey ruleKeyRaw;
              ruleVal = if builtins.length rkv == 2 then builtins.elemAt rkv 1 else null;
              # `noborder` / `norounding` have no boolean window_rule fields
              # in lua; set the corresponding size knob to 0 instead.
              ruleEntry =
                if ruleKeyRaw == "noborder" then "border_size = 0"
                else if ruleKeyRaw == "norounding" then "rounding = 0"
                else if ruleVal == null then "${ruleKey} = true"
                else "${ruleKey} = ${luaStr ruleVal}";
              # Conditions
              mkCond = c:
                let kv = splitFirst ":" c; in
                if builtins.length kv == 2 then
                  { k = trim (builtins.elemAt kv 0); v = trim (builtins.elemAt kv 1); }
                else null;
              condParsed = builtins.filter (x: x != null) (map mkCond condToks);
              matchEntries = map (p: "${renameMatchKey p.k} = ${luaStr p.v}") condParsed;
              matchLua = "match = { ${lib.concatStringsSep ", " matchEntries} }";
            in
            "hl.window_rule({ ${matchLua}, ${ruleEntry} })\n")
          items;

      # ── workspace rules: "WORKSPACE, key:val[, key:val...]" ──
      workspaceRuleLua = items:
        lib.concatMapStrings
          (item:
            let
              parts = map trim (lib.splitString "," item);
              ws = builtins.elemAt parts 0;
              rest = lib.drop 1 parts;
              mkKV = c:
                let
                  kvColon = splitFirst ":" c;
                  kvSpace = splitFirst " " c;
                in
                if builtins.length kvColon == 2 then
                  "${renameWsRuleKey (trim (builtins.elemAt kvColon 0))} = ${luaStr (trim (builtins.elemAt kvColon 1))}"
                else if builtins.length kvSpace == 2 then
                  "${renameWsRuleKey (trim (builtins.elemAt kvSpace 0))} = ${luaStr (trim (builtins.elemAt kvSpace 1))}"
                else
                  "${renameWsRuleKey (trim c)} = true";
              entries = map mkKV rest;
              entriesLua = if entries == [ ] then "" else ", " + (lib.concatStringsSep ", " entries);
            in
            "hl.workspace_rule({ workspace = ${luaStr ws}${entriesLua} })\n")
          items;

      # Gestures use the lua-native schema directly (no string parsing).
      # Per Hyprland's gesture parser (src/config/lua/bindings/
      # LuaBindingsConfigRules.cpp:hlGesture), the valid `action` values are:
      #   workspace, resize, move, special, close, float, fullscreen,
      #   cursor_zoom, scroll_move, unset.
      # `special` uses `workspace_name` (not `modifier`). There is no `exec`
      # action — bind an arbitrary lua function as `action` for that.
      gestureCalls = ''
        hl.gesture({ fingers = 3, direction = "right", action = "workspace" })
        hl.gesture({ fingers = 3, direction = "left",  action = "workspace" })
        hl.gesture({ fingers = 3, direction = "up",    action = "fullscreen" })
        hl.gesture({ fingers = 3, direction = "down",  action = "close" })
        hl.gesture({ fingers = 4, direction = "up",    action = function() hl.exec_cmd("vicinae toggle") end })
        hl.gesture({ fingers = 4, direction = "down",  action = "special", workspace_name = "magic" })
        hl.gesture({ fingers = 4, direction = "pinchin", action = "float" })
      '';

      # ── data ─────────────────────────────────────────────────────────────
      envEntries = [
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "GDK_BACKEND,wayland,x11,*"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SCREENSHOTS_DIR,${myconfig.constants.screenshots}"
      ];

      bezierLines = [
        "easeOutExpo, 0.16, 1, 0.3, 1"
        "easeInOutQuad, 0.45, 0, 0.55, 1"
        "easeOutBack, 0.34, 1.56, 0.64, 1"
      ];

      animationLines = [
        "windows, 1, 3, easeOutExpo"
        "windowsIn, 1, 3, easeOutBack, popin 80%"
        "windowsOut, 1, 2, easeOutExpo, popin 80%"
        "fade, 1, 2, easeOutExpo"
        "border, 1, 3, easeOutExpo"
        "workspaces, 1, 4, easeInOutQuad, slide"
      ];

      windowRulesList = [
        "float, class:(mpv)|(imv)|(showmethekey-gtk)"
        "noborder, class:(showmethekey-gtk)"
        "nofocus, class:(showmethekey-gtk)"
        "pin, class:(showmethekey-gtk)"
        "noinitialfocus, class:(showmethekey-gtk)"
        "move 990 60, class:(showmethekey-gtk)"
        "size 900 170, class:(showmethekey-gtk)"

        "float, class:^(ueberzugpp_layer)$"
        "noanim, class:^(ueberzugpp_layer)$"
        "noshadow, class:^(ueberzugpp_layer)$"
        "noblur, class:^(ueberzugpp_layer)$"
        "noinitialfocus, class:^(ueberzugpp_layer)$"

        "float, class:^(org.kde.gwenview)$"
        "center, class:^(org.kde.gwenview)$"
        "size 80% 80%, class:^(org.kde.gwenview)$"

        "float, title:^(Open File)(.*)$"
        "float, title:^(Select a File)(.*)$"
        "float, title:^(Choose wallpaper)(.*)$"
        "float, title:^(Open Folder)(.*)$"
        "float, title:^(Save As)(.*)$"
        "float, title:^(Library)(.*)$"
        "float, title:^(File Upload)(.*)$"
        "float, title:^(Save File)(.*)$"
        "float, title:^(Enter name of file)(.*)$"
        "center, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"
        "size 50% 50%, title:^(Open File|Select a File|Choose wallpaper|Open Folder|Save As|Library|File Upload|Save File|Enter name of file)(.*)$"

        "float, class:^(xdg-desktop-portal-kde)$"
        "center, class:^(xdg-desktop-portal-kde)$"
        "size 50% 50%, class:^(xdg-desktop-portal-kde)$"

        "suppressevent maximize, class:.*"
        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"

        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
      ]
      ++ (lib.optional
        ((myconfig.constants.hyprland.terminalOpacity or 1.0) < 1.0)
        "opacity ${toString myconfig.constants.hyprland.terminalOpacity} override, class:^(${term})$"
      )
      ++ cfg.windowRules;

      workspaceRulesList = [
        "f[1], gapsout:0, gapsin:0"
      ] ++ (cfg.monitorWorkspaces or [ ]);

      execOnceItems = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "pkill ibus-daemon"
      ] ++ cfg.execOnce;

      hyprlandExtraLua =
        (envLua envEntries)
        + (monitorLua cfg.monitors)
        + (bezierLua bezierLines)
        + (animationLua animationLines)
        + (windowRuleLua windowRulesList)
        + (workspaceRuleLua workspaceRulesList)
        + gestureCalls
        + (execOnceLua execOnceItems);
    in

    {
      catppuccin.hyprland.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprland.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprland.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      home.packages = with pkgs; [
        kdePackages.gwenview
        grimblast
        hyprpaper
        hyprpicker
        imv
        mpv
        brightnessctl
        pavucontrol
        playerctl
        showmethekey
        wl-clipboard
      ];

      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };

        extraConfig = hyprlandExtraLua;

        # Only nested config sections live under `settings.config` — they all
        # render as a single `hl.config({...})` call. Top-level helpers
        # (hl.env/hl.monitor/hl.window_rule/...) are emitted from extraConfig
        # above, built by the small Nix→lua converters in `let` block.
        settings = {
          config = {
            general = {
              gaps_in = myconfig.constants.hyprland.gap or 5;
              gaps_out = (myconfig.constants.hyprland.gap or 10) * 2;
              border_size = myconfig.constants.hyprland.borderSize or 2;

              "col.active_border" = lib.mkDefault (
                if myconfig.constants.theme.catppuccin then
                  "$accent"
                else
                  "rgb(${config.lib.stylix.colors.base0D})"
              );

              "col.inactive_border" = lib.mkForce "rgba(${config.lib.stylix.colors.base02}66)";

              resize_on_border = true;
              allow_tearing = false;
              layout = "dwindle";
            };

            decoration = {
              rounding = myconfig.constants.hyprland.rounding or 0;
              active_opacity = 1.0;
              inactive_opacity = 1.0;
              shadow = {
                enabled = true;
                range = 8;
                render_power = 3;
                color = lib.mkForce "rgba(00000066)";
                offset = "0 3";
              };
              blur = {
                enabled = true;
                size = 8;
                passes = 2;
              };
            };

            animations = {
              enabled = true;
            };

            input = {
              kb_layout = myconfig.constants.keyboardLayout or "us";
              kb_variant = myconfig.constants.keyboardVariant or "";
              kb_options = "grp:ctrl_alt_toggle";
              touchpad = {
                natural_scroll = false;
              };
            };

            cursor = {
              no_hardware_cursors = cfg.noHardwareCursors;
            };

            # `pseudotile` is a dispatcher (bound to a key), NOT a config
            # option — Hyprland's lua reports "unknown config key
            # dwindle.pseudotile" if we set it here. Only `preserve_split`
            # belongs in the dwindle settings block.
            dwindle = {
              preserve_split = true;
            };

            master = {
              new_status = "slave";
              new_on_top = true;
              mfact = 0.5;
            };

            misc = {
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
              background_color = "rgb(${config.lib.stylix.colors.base00})";
            };

            group = {
              "col.border_active" = "rgb(${config.lib.stylix.colors.base0D})";
              "col.border_inactive" = "rgb(${config.lib.stylix.colors.base03})";
              "col.border_locked_active" = "rgb(${config.lib.stylix.colors.base0C})";
              groupbar = {
                text_color = "rgb(${config.lib.stylix.colors.base05})";
                "col.active" = "rgb(${config.lib.stylix.colors.base0D})";
                "col.inactive" = "rgb(${config.lib.stylix.colors.base03})";
              };
            };
          };
        };
      };
    };
}
