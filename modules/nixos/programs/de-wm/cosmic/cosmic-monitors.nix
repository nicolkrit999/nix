{ delib
, lib
, pkgs
, ...
}:
let
  transformName = {
    "0" = "normal";
    "90" = "rotate90";
    "180" = "rotate180";
    "270" = "rotate270";
  };

  fmtNum = n:
    let m = builtins.match "([0-9]+)(\\.[0-9]*[1-9])?(\\.?0*)" (toString n);
    in if m == null then toString n else (builtins.elemAt m 0) + (if builtins.elemAt m 1 == null then "" else builtins.elemAt m 1);

  isFallback = m: m.output == "*";

  commandOf = m:
    if !m.enable then
      "disable ${m.output}"
    else
      lib.concatStringsSep " " [
        "mode ${m.output} ${toString m.width} ${toString m.height}"
        "--refresh ${fmtNum m.refresh}"
        "--scale ${fmtNum m.scale}"
        "--transform ${transformName.${toString m.transform}}"
        "--pos-x ${toString m.x} --pos-y ${toString m.y}"
      ];

  planOf = monitors: map commandOf (lib.filter (m: !isFallback m) monitors);

  nameCharsOk = name: builtins.match "[A-Za-z0-9_.:-]+" name != null;
in
delib.module {
  name = "programs.cosmic";

  nixos.ifEnabled =
    { cfg, ... }:
    let
      named = lib.filter (m: !isFallback m) cfg.monitors;
      names = map (m: m.output) cfg.monitors;
    in
    {
      assertions = [
        {
          assertion = lib.length names == lib.length (lib.unique names);
          message = "programs.cosmic.monitors: output names must be unique";
        }
        {
          assertion = lib.length (lib.filter isFallback cfg.monitors) <= 1;
          message = "programs.cosmic.monitors: at most one \"*\" fallback entry is allowed";
        }
        {
          assertion = lib.all (m: isFallback m || nameCharsOk m.output) cfg.monitors;
          message = "programs.cosmic.monitors: output names may only contain letters, digits and _ . : -";
        }
        {
          assertion = lib.all (m: !m.enable || (m.width > 0 && m.height > 0 && m.refresh > 0)) named;
          message = "programs.cosmic.monitors: every enabled output needs width, height and refresh greater than 0";
        }
        {
          assertion = lib.all (m: m.scale > 0) cfg.monitors;
          message = "programs.cosmic.monitors: scale must be greater than 0";
        }
      ];
    };

  home.ifEnabled =
    { cfg, ... }:
    let
      plan = planOf cfg.monitors;

      inCosmicSession = pkgs.writeShellScript "is-cosmic-session" ''
        case ":$XDG_CURRENT_DESKTOP:" in
          *:COSMIC:*) exit 0 ;;
        esac
        exit 1
      '';

      apply = pkgs.writeShellScript "cosmic-monitors-apply" ''
        set +e
        plan="''${XDG_CONFIG_HOME:-$HOME/.config}/cosmic-monitors/plan"
        randr=${lib.getExe pkgs.cosmic-randr}
        n=0
        until "$randr" list >/dev/null 2>&1; do
          n=$((n + 1))
          if [ "$n" -ge 30 ]; then
            echo "cosmic-monitors: output management never became available; leaving the layout to COSMIC" >&2
            exit 0
          fi
          sleep 1
        done
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          # shellcheck disable=SC2086
          "$randr" $line || echo "cosmic-monitors: failed: cosmic-randr $line" >&2
        done < "$plan"
        exit 0
      '';
    in
    lib.mkIf (plan != [ ]) {
      xdg.configFile."cosmic-monitors/plan".text = lib.concatMapStrings (l: l + "\n") plan;

      systemd.user.services.cosmic-monitors = {
        Unit = {
          Description = "Apply the declared COSMIC monitor layout";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecCondition = "${inCosmicSession}";
          ExecStart = "${apply}";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
