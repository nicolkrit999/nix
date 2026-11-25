{ delib
, lib
, config
, pkgs
, ...
}:
let
  wmOn = myconfig: wm: myconfig.programs.${wm}.enable or false;
in
delib.module {
  name = "programs.monitor-picker";
  options = delib.singleEnableOption true;

  home.always = { cfg, myconfig, ... }:
    let
      user = myconfig.constants.user;
      uid = toString (lib.attrByPath [ "users" "users" user "uid" ] null config);
      stateDir = "/run/user/${if uid == "" then "1000" else uid}/monitor-picker";
    in
    {
      imports = [
        ({ options, config, ... }: {
          config = lib.mkIf cfg.enable (lib.mkMerge [
            (lib.mkIf (wmOn myconfig "hyprland") {
              wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
                do
                  local p = (os.getenv("XDG_RUNTIME_DIR") or "") .. "/monitor-picker/monitors.lua"
                  local f = io.open(p, "r")
                  if f then
                    f:close()
                    pcall(dofile, p)
                  end
                end
              '';
            })
            (lib.mkIf (wmOn myconfig "mango") {
              wayland.windowManager.mango.extraConfig = lib.mkAfter ''
                source_optional=${stateDir}/monitors.conf
              '';
            })
            (lib.mkIf (wmOn myconfig "niri" && config.programs.niri.settings != null) {
              programs.niri.config = options.programs.niri.config.default ++ [
                {
                  name = "include";
                  arguments = [ "${stateDir}/monitor.kdl" ];
                  properties = { optional = true; };
                  children = [ ];
                }
              ];
            })
          ]);
        })
      ];
    };

  home.ifEnabled = { myconfig, ... }:
    let
      on = wmOn myconfig;
      active = on "hyprland" || on "niri" || on "mango";
      wmPackage = wm: fallback: lib.attrByPath [ "programs" wm "package" ] fallback config;
      wmTools =
        lib.optional (on "hyprland") (wmPackage "hyprland" pkgs.hyprland)
        ++ lib.optional (on "niri") (wmPackage "niri" pkgs.niri)
        ++ lib.optional (on "mango") (wmPackage "mango" null);

      hyprDeclared = lib.filter (o: o != "" && o != "*")
        (map (m: m.output or "") (myconfig.programs.hyprland.monitors or [ ]));
      niriDeclared = builtins.attrNames (myconfig.programs.niri.outputs or { });
      mangoName = s:
        let m = builtins.match ".*name:\\^?([^,$]*)\\$?(,.*)?" s;
        in if m == null then null else builtins.head m;
      mangoDeclared = lib.filter (n: n != null && n != "")
        (map mangoName (myconfig.programs.mango.monitors or [ ]));

      declared = pkgs.linkFarm "monitor-picker-declared" (
        lib.mapAttrsToList
          (name: entries: {
            inherit name;
            path = pkgs.writeText "monitor-picker-declared-${name}" (lib.concatLines entries);
          })
          {
            hyprland = hyprDeclared;
            niri = niriDeclared;
            mango = mangoDeclared;
          }
      );

      picker = pkgs.writeShellApplication {
        name = "monitor-picker";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          jq
          nwg-displays
          procps
          socat
          systemd
          wl-mirror
          wlr-randr
        ] ++ lib.filter (p: p != null) wmTools;
        runtimeEnv.MONITOR_PICKER_DECLARED = "${declared}";
        text = builtins.readFile ./monitor-picker.sh;
      };

      mirror = pkgs.writeShellScriptBin "monitor-mirror" ''
        exec ${lib.getExe picker} mirror "$@"
      '';

      desktopItem = pkgs.makeDesktopItem {
        name = "monitor-picker";
        desktopName = "Monitor Setup";
        comment = "Arrange, mirror or disable monitors";
        exec = "${lib.getExe picker} open";
        icon = "preferences-desktop-display";
        categories = [ "Settings" "HardwareSettings" ];
      };
    in
    lib.mkIf active {
      home.packages = [ picker mirror desktopItem pkgs.wl-mirror ];

      systemd.user.services.monitor-picker = {
        Unit = {
          Description = "Open nwg-displays when an undeclared monitor is plugged in";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install.WantedBy = [ "graphical-session.target" ];
        Service = {
          ExecStart = "${lib.getExe picker} watch";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
}
