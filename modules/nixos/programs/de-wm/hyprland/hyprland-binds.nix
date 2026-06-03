{ delib
, lib
, ...
}:
delib.module {
  name = "programs.hyprland";
  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      inherit (lib.generators) mkLuaInline;

      mod = "SUPER";
      term = myconfig.constants.terminal.name or "alacritty";
      browser = myconfig.constants.browser or "firefox";
      rawFm = myconfig.constants.fileManager or "dolphin";
      rawEd = myconfig.constants.editor or "vscode";
      termApps = [ "nvim" "neovim" "vim" "nano" "hx" "helix" "yazi" "ranger" "lf" "nnn" ];
      smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
      smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;

      caelestiaActiveOnHyprland =
        (myconfig.programs.caelestia.enable or false)
        && (myconfig.programs.caelestia.enableOnHyprland or false);
      noctaliaActiveOnHyprland =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnHyprland or false);

      shellMenu =
        if caelestiaActiveOnHyprland then "caelestiaQS"
        else if noctaliaActiveOnHyprland then "noctalia-shell ipc call toggleAppLauncher"
        else "true";

      shellLock =
        if caelestiaActiveOnHyprland then "caelestiaLogout lock"
        else if noctaliaActiveOnHyprland then "noctalia-shell ipc call lockScreen lock"
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

      bindelList =
        if shellActiveOnHyprland then [
          (mkBind { key = "XF86AudioRaiseVolume"; dispatcher = exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioLowerVolume"; dispatcher = exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioMute"; dispatcher = exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioMicMute"; dispatcher = exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86MonBrightnessUp"; dispatcher = exec "brightnessctl set 5%+"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86MonBrightnessDown"; dispatcher = exec "brightnessctl set 5%-"; flags = { locked = true; repeating = true; }; })
          (mkBind { mods = mod; key = "bracketright"; dispatcher = exec "brightnessctl set 5%+"; flags = { locked = true; repeating = true; }; })
          (mkBind { mods = mod; key = "bracketleft"; dispatcher = exec "brightnessctl set 5%-"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86KbdBrightnessUp"; dispatcher = exec "brightnessctl --device='*::kbd_backlight' set +10%"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86KbdBrightnessDown"; dispatcher = exec "brightnessctl --device='*::kbd_backlight' set 10%-"; flags = { locked = true; repeating = true; }; })
        ] else [
          (mkBind { key = "XF86AudioRaiseVolume"; dispatcher = exec "swayosd-client --output-volume raise"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioLowerVolume"; dispatcher = exec "swayosd-client --output-volume lower"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioMute"; dispatcher = exec "swayosd-client --output-volume mute-toggle"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86AudioMicMute"; dispatcher = exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86MonBrightnessUp"; dispatcher = exec "swayosd-client --brightness raise"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86MonBrightnessDown"; dispatcher = exec "swayosd-client --brightness lower"; flags = { locked = true; repeating = true; }; })
          (mkBind { mods = mod; key = "bracketright"; dispatcher = exec "swayosd-client --brightness raise"; flags = { locked = true; repeating = true; }; })
          (mkBind { mods = mod; key = "bracketleft"; dispatcher = exec "swayosd-client --brightness lower"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86KbdBrightnessUp"; dispatcher = exec "swayosd-client --keyboard-brightness raise"; flags = { locked = true; repeating = true; }; })
          (mkBind { key = "XF86KbdBrightnessDown"; dispatcher = exec "swayosd-client --keyboard-brightness lower"; flags = { locked = true; repeating = true; }; })
        ];

      bindlList =
        if shellActiveOnHyprland then [
          (mkBind { key = "XF86AudioNext"; dispatcher = exec "playerctl next"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPause"; dispatcher = exec "playerctl play-pause"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPlay"; dispatcher = exec "playerctl play-pause"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPrev"; dispatcher = exec "playerctl previous"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioStop"; dispatcher = exec "playerctl stop"; flags = { locked = true; }; })
        ] else [
          (mkBind { key = "XF86AudioNext"; dispatcher = exec "swayosd-client --playerctl next"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPause"; dispatcher = exec "swayosd-client --playerctl play-pause"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPlay"; dispatcher = exec "swayosd-client --playerctl play-pause"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioPrev"; dispatcher = exec "swayosd-client --playerctl previous"; flags = { locked = true; }; })
          (mkBind { key = "XF86AudioStop"; dispatcher = exec "swayosd-client --playerctl stop"; flags = { locked = true; }; })
          (mkBind { key = "Caps_Lock"; dispatcher = exec "swayosd-client --caps-lock"; flags = { locked = true; }; })
        ];

      wsKey = n: if n == 0 then "10" else toString n;
      wsBind = n: mkBind { mods = mod; key = toString n; dispatcher = focusWs (wsKey n); };
      wsMoveBind = n: mkBind { mods = "${mod}+SHIFT"; key = toString n; dispatcher = moveToWsSilent (wsKey n); };
    in
    {
      wayland.windowManager.hyprland.settings = {
        bind = [
          (mkBind { mods = "${mod}+SHIFT"; key = "C"; dispatcher = "hl.dsp.window.close()"; })
          (mkBind { mods = mod; key = "T"; dispatcher = ''hl.dsp.layout("togglesplit")''; })
          (mkBind { mods = mod; key = "space"; dispatcher = ''hl.dsp.window.float({ action = "toggle" })''; })
          (mkBind { mods = mod; key = "M"; dispatcher = "hl.dsp.window.fullscreen()"; })
          (mkBind { mods = "${mod}+ALT"; key = "P"; dispatcher = "hl.dsp.window.pin()"; })
          (mkBind { mods = mod; key = "P"; dispatcher = exec "hyprctl dispatch togglefloating && hyprctl dispatch pin"; })

          (mkBind { mods = mod; key = "A"; dispatcher = exec "vicinae toggle"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "A"; dispatcher = exec shellMenu; })
          (mkBind { mods = mod; key = "return"; dispatcher = exec term; })
          (mkBind { mods = mod; key = "F"; dispatcher = exec smartFm; })
          (mkBind { mods = mod; key = "B"; dispatcher = exec browser; })
          (mkBind { mods = mod; key = "C"; dispatcher = exec smartEd; })

          (mkBind { mods = "${mod}+SHIFT"; key = "Delete"; dispatcher = "hl.dsp.exit()"; })
          (mkBind { mods = mod; key = "Delete"; dispatcher = exec shellLock; })

          (mkBind { mods = mod; key = "period"; dispatcher = exec "vicinae vicinae://launch/core/search-emojis"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "P"; dispatcher = exec "hyprpicker -an"; })
          (mkBind { mods = mod; key = "V"; dispatcher = exec "vicinae vicinae://launch/clipboard/history"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "R"; dispatcher = exec "hyprctl reload"; })
          (mkBind { mods = mod; key = "N"; dispatcher = exec "swaync-client -t"; })

          (mkBind { mods = "${mod}+ALT"; key = "W"; dispatcher = exec "pkill -SIGUSR2 waybar"; })
          (mkBind { mods = "${mod}+SHIFT"; key = "W"; dispatcher = exec "pkill -x -SIGUSR1 waybar"; })

          (mkBind { key = "Print"; dispatcher = exec "grimblast --notify --freeze copysave output"; })
          (mkBind { mods = "SUPER+CTRL"; key = "3"; dispatcher = exec "grimblast --notify --freeze copysave output"; })
          (mkBind { mods = "SUPER+CTRL"; key = "4"; dispatcher = exec "grimblast --notify --freeze copysave area"; })

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
        ]
        ++ (map wsBind [ 1 2 3 4 5 6 7 8 9 0 ])
        ++ (map wsMoveBind [ 1 2 3 4 5 6 7 8 9 0 ])
        ++ [
          (mkBind { mods = mod; key = "mouse:272"; dispatcher = "hl.dsp.window.drag()"; flags = { mouse = true; }; })
          (mkBind { mods = mod; key = "mouse:273"; dispatcher = "hl.dsp.window.resize()"; flags = { mouse = true; }; })
        ]
        ++ bindelList
        ++ bindlList
        ++ (cfg.extraBinds or [ ])
        ++ (cfg.extraBindl or [ ]);
      };
    };
}
