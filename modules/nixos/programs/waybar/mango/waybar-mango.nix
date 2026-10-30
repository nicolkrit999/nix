{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-mango";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      w = (import ../contrast-lib.nix { inherit lib; }).mkWaybar {
        inherit pkgs myconfig;
        colors = config.lib.stylix.colors.withHashtag;
      };
      inherit (w) c t jq;

      isMangoEnabled = parent.mango.enable;
      noctaliaActiveOnMango = parent.noctalia.enable && parent.noctalia.enableOnMango;

      extractMonitorName = monStr:
        let m = builtins.match ".*name:\\^?([^$,]+)\\$?,.*" monStr;
        in if m != null then builtins.head m else null;
      monitorNames = lib.filter (n: n != null) (map extractMonitorName parent.mango.monitors);

      watchMonitors = sel: filter: ''
        mmsg watch all-monitors 2>/dev/null \
          | ${jq} --unbuffered -r ${sel.args}'${sel.prelude}.monitors[] | select(.name == $mon) | ${filter}'' + "'";

      mkPerMonitorModules = sel: {
        "custom/tags" = {
          exec = ''
            ${watchMonitors sel ''[.tags[] | if .is_active then "A\(.index)" elif (.client_count // 0) > 0 then "O\(.index)" else empty end] | join(" ")''} \
              | awk -v active_bg='${c.base05}' -v active_fg='${t.fg.active}' -v active_ring='${t.ring.active}' -v occupied='${t.fg.pill}' -v empty='${t.fg.tagEmpty}' '
                  {
                    out = ""
                    for (i = 1; i <= NF; i++) {
                      n = substr($i, 2)
                      if (substr($i, 1, 1) == "A") out = out "<span background=\"" active_bg "\" foreground=\"" active_fg "\" underline=\"double\" underline_color=\"" active_ring "\" weight=\"bold\">  " n "  </span>"
                      else out = out "<span color=\"" occupied "\">  " n "  </span>"
                    }
                    if (out == "") out = "<span color=\"" empty "\">  -  </span>"
                    print out
                    fflush()
                  }'
          '';
          format = "{}";
          restart-interval = 5;
          tooltip = false;
        };

        "custom/layout" = {
          format = "{}";
          exec = ''
            ${watchMonitors sel ''.layout_symbol // ""''} \
              | while IFS= read -r layout; do
                  case "$layout" in
                    S)   echo "<span color='${t.accent c.base0C}'>󰕕</span> Scroller" ;;
                    T)   echo "<span color='${t.accent c.base0D}'>󰕴</span> Tile" ;;
                    M)   echo "<span color='${t.accent c.base0E}'>󰊓</span> Mono" ;;
                    G)   echo "<span color='${t.accent c.base0A}'>󰕰</span> Grid" ;;
                    K)   echo "<span color='${t.accent c.base0B}'>󰓹</span> Deck" ;;
                    CT)  echo "<span color='${t.accent c.base0D}'>󰃻</span> Center" ;;
                    VT)  echo "<span color='${t.accent c.base0D}'>󰬔</span> VTile" ;;
                    VS)  echo "<span color='${t.accent c.base0C}'>󰬔</span> VScroll" ;;
                    VG)  echo "<span color='${t.accent c.base0A}'>󰬔</span> VGrid" ;;
                    VK)  echo "<span color='${t.accent c.base0B}'>󰬔</span> VDeck" ;;
                    RT)  echo "<span color='${t.accent c.base0D}'>󰕴</span> RTile" ;;
                    DW)  echo "<span color='${t.accent c.base0B}'>󰕰</span> Dwindle" ;;
                    F)   echo "<span color='${t.accent c.base0A}'>󰕰</span> Fair" ;;
                    VF)  echo "<span color='${t.accent c.base0A}'>󰬔</span> VFair" ;;
                    *)   echo "$layout" ;;
                  esac
                done
          '';
          restart-interval = 5;
          on-click = "cur=$(mmsg get all-monitors 2>/dev/null | ${jq} -r '.monitors[] | select(.active == true) | .layout_symbol'); if [ \"$cur\" = \"S\" ]; then mmsg dispatch setlayout,tile; else mmsg dispatch setlayout,scroller; fi";
          on-click-right = "mmsg dispatch setlayout,scroller";
          tooltip = false;
        };

        "custom/window" = {
          exec = ''
            ${watchMonitors sel ''.active_client.title // "" | .[0:25] | @html''} \
              | while IFS= read -r title; do
                  if [ -z "$title" ]; then
                    echo "${w.userHost}"
                  else
                    printf '%s\n' "$title"
                  fi
                done
          '';
          restart-interval = 5;
          tooltip = false;
        };
      };

      knownLayouts = [
        { code = "en"; glob = "English*|US*|us*|en*"; }
        { code = "it"; glob = "Italian*|it*|ita*"; }
        { code = "de"; glob = "German*|de*|deu*"; }
        { code = "fr"; glob = "French*|fr*|fra*"; }
      ];
      extraLayouts = map (code: { inherit code; glob = "${code}*"; })
        (lib.subtractLists ((map (l: l.code) knownLayouts) ++ [ "alt" "icons" ])
          (map (lib.removePrefix "format-") (lib.filter (lib.hasPrefix "format-") (lib.attrNames cfg.waybarLayout))));
      caseArm = pattern: cmd:
        let p = "${pattern})";
        in "${p}${lib.concatStrings (lib.replicate (lib.max 1 (22 - lib.stringLength p)) " ")}${cmd} ;;";
      languageArms = lib.concatStringsSep "\n        " (
        map (l: caseArm l.glob ''echo "${cfg.waybarLayout."format-${l.code}" or (lib.toUpper l.code)}"'') (knownLayouts ++ extraLayouts)
        ++ [ (caseArm "*" ''echo "$layout"'') ]
      );

      waybarConfig = w.bar // w.modules // {
        modules-left = [ "custom/tags" "custom/layout" ];
        modules-center = [ "clock" "custom/window" ];
        modules-right = w.modulesRight "custom/language";

        "custom/language" = {
          format = "{}";
          exec = ''
            mmsg watch keyboardlayout 2>/dev/null \
              | ${jq} --unbuffered -r '.layout // ""' \
              | while IFS= read -r layout; do
                  case "$layout" in
                    ${languageArms}
                  esac
                done
          '';
          restart-interval = 5;
          tooltip = false;
        };
      };

      mkBar = mon: waybarConfig // (mkPerMonitorModules { args = "--arg mon \"${mon}\" "; prelude = ""; }) // { output = mon; };
      focusedSel = { args = ""; prelude = "first(.monitors[] | select(.active == true) | .name) as $mon | "; };
      bars =
        if monitorNames != [ ]
        then map mkBar monitorNames
        else [ (waybarConfig // (mkPerMonitorModules focusedSel)) ];
    in
    w.home
      {
        name = "mango";
        title = "Mango";
        enable = isMangoEnabled;
        target = "mango-session.target";
        config = bars;
        css = builtins.readFile ./style.css;
      } // {
      assertions = [
        {
          assertion = !(isMangoEnabled && noctaliaActiveOnMango);
          message = "waybar-mango is enabled together with an active noctalia shell on Mango - disable one.";
        }
      ];
    };
}
