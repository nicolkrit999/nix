{ delib
, lib
, ...
}:
delib.module {
  name = "programs.hyprland";
  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      inherit (lib.generators) mkLuaInline;

      mod = "SUPER";
      term = myconfig.constants.terminal.name;
      browser = myconfig.constants.browser;
      rawFm = myconfig.constants.fileManager;
      rawEd = myconfig.constants.editor;
      termApps = myconfig.constants.terminalApps;
      smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
      smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;

      caelestiaActiveOnHyprland = parent.caelestia.enable && parent.caelestia.enableOnHyprland;
      noctaliaActiveOnHyprland = parent.noctalia.enable && parent.noctalia.enableOnHyprland;

      vicinaeEnabled = parent.vicinae.enable or true;

      shellMenu =
        if caelestiaActiveOnHyprland then "caelestiaqs ipc call drawers toggle launcher"
        else if noctaliaActiveOnHyprland then "noctalia msg panel-toggle launcher"
        else if vicinaeEnabled then "vicinae toggle"
        else null;

      shellLock =
        if caelestiaActiveOnHyprland then "caelestiaqs ipc call lock lock"
        else if noctaliaActiveOnHyprland then "noctalia msg session lock"
        else "loginctl lock-session";

      shellActiveOnHyprland = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;

      luaQ = s:
        let
          esc = builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s;
        in
        "\"${esc}\"";

      mkBind = { mods ? "", key, dispatcher, flags ? null }:
        let
          keyStr = if mods == "" then key else "${mods} + ${key}";
          base = [ keyStr (mkLuaInline dispatcher) ];
        in
        { _args = if flags == null then base else base ++ [ flags ]; };

      exec = cmd: "hl.dsp.exec_cmd(${luaQ cmd})";
      focusDir = d: "hl.dsp.focus({ direction = \"${d}\" })";
      swapDir = d: "hl.dsp.window.swap({ direction = \"${d}\" })";
      focusWs = ws: "hl.dsp.focus({ workspace = \"${ws}\" })";
      moveToWs = ws: "hl.dsp.window.move({ workspace = \"${ws}\" })";
      moveToWsSilent = ws: "hl.dsp.window.move({ workspace = \"${ws}\", follow = false })";
      resizeBy = x: y: "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
      focusMonitor = m: "hl.dsp.focus({ monitor = ${luaQ m} })";
      moveToMonitor = m: "hl.dsp.window.move({ monitor = ${luaQ m} })";

      repeatBind = { mods ? "", key, cmd }: mkBind {
        inherit mods key;
        dispatcher = exec cmd;
        flags = { locked = true; repeating = true; };
      };
      lockedBind = { key, cmd }: mkBind {
        inherit key;
        dispatcher = exec cmd;
        flags = { locked = true; };
      };

      bindelList = map repeatBind (
        if shellActiveOnHyprland then [
          { key = "XF86AudioRaiseVolume"; cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; }
          { key = "XF86AudioLowerVolume"; cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
          { key = "XF86AudioMute"; cmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
          { key = "XF86AudioMicMute"; cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
          { key = "XF86MonBrightnessUp"; cmd = "brightnessctl set 5%+"; }
          { key = "XF86MonBrightnessDown"; cmd = "brightnessctl set 5%-"; }
          { mods = mod; key = "bracketright"; cmd = "brightnessctl set 5%+"; }
          { mods = mod; key = "bracketleft"; cmd = "brightnessctl set 5%-"; }
          { key = "XF86KbdBrightnessUp"; cmd = "brightnessctl --device='*::kbd_backlight' set +10%"; }
          { key = "XF86KbdBrightnessDown"; cmd = "brightnessctl --device='*::kbd_backlight' set 10%-"; }
        ] else [
          { key = "XF86AudioRaiseVolume"; cmd = "swayosd-client --output-volume raise"; }
          { key = "XF86AudioLowerVolume"; cmd = "swayosd-client --output-volume lower"; }
          { key = "XF86AudioMute"; cmd = "swayosd-client --output-volume mute-toggle"; }
          { key = "XF86AudioMicMute"; cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
          { key = "XF86MonBrightnessUp"; cmd = "swayosd-client --brightness raise"; }
          { key = "XF86MonBrightnessDown"; cmd = "swayosd-client --brightness lower"; }
          { mods = mod; key = "bracketright"; cmd = "swayosd-client --brightness raise"; }
          { mods = mod; key = "bracketleft"; cmd = "swayosd-client --brightness lower"; }
          { key = "XF86KbdBrightnessUp"; cmd = "swayosd-client --keyboard-brightness raise"; }
          { key = "XF86KbdBrightnessDown"; cmd = "swayosd-client --keyboard-brightness lower"; }
        ]
      );

      bindlList = map lockedBind (
        if shellActiveOnHyprland then [
          { key = "XF86AudioNext"; cmd = "playerctl next"; }
          { key = "XF86AudioPause"; cmd = "playerctl play-pause"; }
          { key = "XF86AudioPlay"; cmd = "playerctl play-pause"; }
          { key = "XF86AudioPrev"; cmd = "playerctl previous"; }
          { key = "XF86AudioStop"; cmd = "playerctl stop"; }
        ] else [
          { key = "XF86AudioNext"; cmd = "swayosd-client --playerctl next"; }
          { key = "XF86AudioPause"; cmd = "swayosd-client --playerctl play-pause"; }
          { key = "XF86AudioPlay"; cmd = "swayosd-client --playerctl play-pause"; }
          { key = "XF86AudioPrev"; cmd = "swayosd-client --playerctl previous"; }
          { key = "XF86AudioStop"; cmd = "swayosd-client --playerctl stop"; }
          { key = "Caps_Lock"; cmd = "swayosd-client --caps-lock"; }
        ]
      );

      wsKey = n: if n == 0 then "10" else toString n;
      wsBind = n: mkBind { mods = mod; key = toString n; dispatcher = focusWs (wsKey n); };
      wsMoveBind = n: mkBind { mods = "${mod}+SHIFT"; key = toString n; dispatcher = moveToWsSilent (wsKey n); };
      wsFollowBind = n: mkBind { mods = "${mod}+ALT"; key = toString n; dispatcher = moveToWs (wsKey n); };
    in
    {
      wayland.windowManager.hyprland.settings = {
        bind = lib.flatten [
          (mkBind { mods = "${mod}+SHIFT"; key = "C"; dispatcher = "hl.dsp.window.close()"; })
          (mkBind { mods = mod; key = "T"; dispatcher = ''hl.dsp.layout("togglesplit")''; })
          (mkBind { mods = mod; key = "space"; dispatcher = ''hl.dsp.window.float({ action = "toggle" })''; })
          (mkBind { mods = mod; key = "M"; dispatcher = "hl.dsp.window.fullscreen()"; })
          (mkBind { mods = "${mod}+ALT"; key = "P"; dispatcher = "hl.dsp.window.pin()"; })
          (mkBind { mods = mod; key = "P"; dispatcher = exec "hyprctl dispatch 'hl.dsp.window.float({ action = \"toggle\" })' && hyprctl dispatch 'hl.dsp.window.resize({ x = 800, y = 450, relative = false })' && hyprctl dispatch 'hl.dsp.window.pin()'"; })

          (lib.optional vicinaeEnabled (mkBind { mods = mod; key = "A"; dispatcher = exec "vicinae toggle"; }))
          (lib.optional (shellMenu != null) (mkBind { mods = "${mod}+SHIFT"; key = "A"; dispatcher = exec shellMenu; }))
          (mkBind { mods = mod; key = "return"; dispatcher = exec term; })
          (mkBind { mods = mod; key = "F"; dispatcher = exec smartFm; })
          (mkBind { mods = mod; key = "B"; dispatcher = exec browser; })
          (mkBind { mods = mod; key = "C"; dispatcher = exec smartEd; })

          (mkBind { mods = "${mod}+SHIFT"; key = "Delete"; dispatcher = "hl.dsp.exit()"; })
          (mkBind { mods = mod; key = "Delete"; dispatcher = exec shellLock; })

          (lib.optional vicinaeEnabled (mkBind { mods = mod; key = "period"; dispatcher = exec "vicinae vicinae://launch/core/search-emojis"; }))
          (mkBind { mods = "${mod}+SHIFT"; key = "P"; dispatcher = exec "hyprpicker -an"; })
          (lib.optional vicinaeEnabled (mkBind { mods = mod; key = "V"; dispatcher = exec "vicinae vicinae://launch/clipboard/history"; }))
          (mkBind { mods = "${mod}+SHIFT"; key = "R"; dispatcher = exec "hyprctl reload"; })
          (mkBind { mods = mod; key = "N"; dispatcher = exec "swaync-client -t"; })

          (mkBind { mods = "${mod}+ALT"; key = "W"; dispatcher = exec "pkill -SIGUSR2 waybar"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "W"; dispatcher = exec "pkill -SIGUSR1 waybar"; })

          (mkBind { key = "Print"; dispatcher = exec "grimblast --notify --freeze copysave output"; })
          (mkBind { mods = "${mod}+CTRL"; key = "3"; dispatcher = exec "grimblast --notify --freeze copysave output"; })
          (mkBind { mods = "${mod}+CTRL"; key = "4"; dispatcher = exec "grimblast --notify --freeze copysave area"; })

          (mkBind { mods = mod; key = "left"; dispatcher = focusDir "left"; })
          (mkBind { mods = mod; key = "H"; dispatcher = focusDir "left"; })
          (mkBind { mods = mod; key = "right"; dispatcher = focusDir "right"; })
          (mkBind { mods = mod; key = "L"; dispatcher = focusDir "right"; })
          (mkBind { mods = mod; key = "up"; dispatcher = focusDir "up"; })
          (mkBind { mods = mod; key = "K"; dispatcher = focusDir "up"; })
          (mkBind { mods = mod; key = "down"; dispatcher = focusDir "down"; })
          (mkBind { mods = mod; key = "J"; dispatcher = focusDir "down"; })

          (mkBind { mods = "${mod}+SHIFT"; key = "left"; dispatcher = swapDir "left"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "H"; dispatcher = swapDir "left"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "right"; dispatcher = swapDir "right"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "L"; dispatcher = swapDir "right"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "up"; dispatcher = swapDir "up"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "K"; dispatcher = swapDir "up"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "down"; dispatcher = swapDir "down"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "J"; dispatcher = swapDir "down"; })

          (mkBind { mods = "${mod}+CTRL"; key = "left"; dispatcher = resizeBy (-60) 0; })
          (mkBind { mods = "${mod}+CTRL"; key = "right"; dispatcher = resizeBy 60 0; })
          (mkBind { mods = "${mod}+CTRL"; key = "up"; dispatcher = resizeBy 0 (-60); })
          (mkBind { mods = "${mod}+CTRL"; key = "down"; dispatcher = resizeBy 0 60; })

          (mkBind { mods = mod; key = "S"; dispatcher = ''hl.dsp.workspace.toggle_special("magic")''; })
          (mkBind { mods = "${mod}+SHIFT"; key = "S"; dispatcher = moveToWs "special:magic"; })

          (mkBind { mods = "${mod}+CTRL"; key = "H"; dispatcher = focusMonitor "-1"; })
          (mkBind { mods = "${mod}+CTRL"; key = "L"; dispatcher = focusMonitor "+1"; })
          (mkBind { mods = "${mod}+ALT"; key = "H"; dispatcher = moveToMonitor "-1"; })
          (mkBind { mods = "${mod}+ALT"; key = "L"; dispatcher = moveToMonitor "+1"; })
        ]
        ++ (map wsBind [ 1 2 3 4 5 6 7 8 9 0 ])
        ++ (map wsMoveBind [ 1 2 3 4 5 6 7 8 9 0 ])
        ++ (map wsFollowBind [ 1 2 3 4 5 6 7 8 9 0 ])
        ++ [
          (mkBind { mods = mod; key = "mouse:272"; dispatcher = "hl.dsp.window.drag()"; flags = { mouse = true; }; })
          (mkBind { mods = mod; key = "mouse:273"; dispatcher = "hl.dsp.window.resize()"; flags = { mouse = true; }; })
        ]
        ++ bindelList
        ++ bindlList
        ++ cfg.extraBinds;
      };
    };
}
