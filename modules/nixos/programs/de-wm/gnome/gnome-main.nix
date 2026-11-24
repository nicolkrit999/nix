{ delib
, pkgs
, lib
, ...
}:
let
  rotationName = {
    "0" = "normal";
    "90" = "left";
    "180" = "upside_down";
    "270" = "right";
  };

  isFallback = m: m.output == "*";
  nameCharsOk = name: builtins.match "[A-Za-z0-9_.:-]+" name != null;
  esc = lib.escapeXML;
  tag = t: v: "<${t}>${esc (toString v)}</${t}>";

  specXml = m: "<monitorspec>${tag "connector" m.output}${tag "vendor" m.vendor}${tag "product" m.product}${tag "serial" m.serial}</monitorspec>";
  monitorXml = m: w: h: r:
    "<monitor>${specXml m}<mode>${tag "width" w}${tag "height" h}${tag "rate" r}</mode></monitor>";

  isReplica = m: m.enable && m.mirror != "";

  logicalXml = primaryOut: withReplicas: named: src:
    let
      replicas = lib.optionals withReplicas (lib.filter (r: isReplica r && r.mirror == src.output) named);
      first = lib.head replicas;
      monitors =
        if replicas == [ ] then
          monitorXml src src.width src.height src.refresh
        else
          monitorXml src first.width first.height first.refresh
          + lib.concatMapStrings (r: monitorXml r r.width r.height r.refresh) replicas;
    in
    "<logicalmonitor>${tag "x" src.x}${tag "y" src.y}${tag "scale" src.scale}${monitors}"
    + "<transform>${tag "rotation" rotationName.${toString src.transform}}<flipped>no</flipped></transform>"
    + lib.optionalString (src.output == primaryOut) "<primary>yes</primary>"
    + "</logicalmonitor>";

  configurationXml = primaryOut: withReplicas: named:
    let
      active = lib.filter (m: m.enable && !isReplica m) named;
      disabled = lib.optionals withReplicas (lib.filter (m: !m.enable) named);
    in
    "<configuration><layoutmode>logical</layoutmode>"
    + lib.concatMapStrings (logicalXml primaryOut withReplicas named) active
    + lib.optionalString (disabled != [ ]) "<disabled>${lib.concatMapStrings specXml disabled}</disabled>"
    + "</configuration>";

  incomplete = m:
    (m.enable && (m.width <= 0 || m.height <= 0 || m.refresh <= 0))
    || m.vendor == "" || m.product == "" || m.serial == "";

  primaryOf = candidates:
    let marked = lib.filter (m: m.primary) candidates;
    in if marked != [ ] then (lib.head marked).output else (lib.head candidates).output;

  monitorsXml = primaryOut: named:
    let hasOptional = lib.any (m: isReplica m || !m.enable) named;
    in
    "<monitors version=\"2\">"
    + configurationXml primaryOut true named
    + lib.optionalString hasOptional (configurationXml primaryOut false named)
    + "</monitors>\n";

  rectOf = named: m:
    let
      replicas = lib.filter (r: isReplica r && r.mirror == m.output) named;
      w = if replicas == [ ] then m.width else (lib.head replicas).width;
      h = if replicas == [ ] then m.height else (lib.head replicas).height;
      rotated = m.transform == 90 || m.transform == 270;
    in
    {
      inherit (m) x y;
      w = (if rotated then h else w) / m.scale;
      h = (if rotated then w else h) / m.scale;
    };

  overlap = a: b: a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
in
delib.module {
  name = "programs.gnome";
  options =
    with delib;
    moduleOptions {
      pinnedApps = listOfOption str [ ];
      extraBinds = listOfOption attrs [ ];
      monitors = listOfOption
        (submodule {
          options = {
            output = strOption "*";
            width = intOption 0;
            height = intOption 0;
            refresh = numberOption 0;
            scale = numberOption 1.0;
            x = intOption 0;
            y = intOption 0;
            transform = enumOption [ 0 90 180 270 ] 0;
            enable = boolOption true;
            mirror = strOption "";
            primary = boolOption false;
            vendor = strOption "";
            product = strOption "";
            serial = strOption "";
          };
        })
        [ ];
      wmKeybindings = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = "Extra org/gnome/desktop/wm/keybindings entries. Each list replaces the schema default for that key, so include the default accelerators you want to keep. `close` is appended to the module's own <Super><Shift>c.";
        example = { switch-to-workspace-left = [ "<Super>Page_Up" "XF86Tools" ]; };
      };
    };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      named = lib.filter (m: !isFallback m) cfg.monitors;
      names = map (m: m.output) cfg.monitors;
      mirrored = lib.filter isReplica named;
      candidates = lib.filter (m: m.enable && !isReplica m) named;
      bad = lib.filter incomplete named;
      usable = named != [ ] && bad == [ ] && candidates != [ ] && lib.all (m: m.scale > 0) named;
      primaryOut = if usable then primaryOf candidates else "";
      rects = map (rectOf named) candidates;
      pairs = lib.concatLists (lib.imap0 (i: a: map (b: { inherit a b; }) (lib.drop (i + 1) rects)) rects);
      msg = text: "programs.gnome.monitors: ${text}";
    in
    {
      assertions = [
        {
          assertion = lib.length names == lib.length (lib.unique names);
          message = msg "output names must be unique";
        }
        {
          assertion = lib.length (lib.filter isFallback cfg.monitors) <= 1;
          message = msg "at most one \"*\" fallback entry is allowed";
        }
        {
          assertion = lib.all (m: isFallback m || nameCharsOk m.output) cfg.monitors;
          message = msg "output names may only contain letters, digits and _ . : -";
        }
        {
          assertion = lib.all (m: m.scale > 0) cfg.monitors;
          message = msg "scale must be greater than 0";
        }
        {
          assertion = lib.all (m: m.mirror == "" || nameCharsOk m.mirror) cfg.monitors;
          message = msg "mirror names may only contain letters, digits and _ . : -";
        }
        {
          assertion = lib.all (m: m.mirror != m.output) mirrored;
          message = msg "an output cannot mirror itself";
        }
        {
          assertion = lib.all (m: lib.any (s: s.output == m.mirror && s.enable && s.mirror == "") named) mirrored;
          message = msg "a mirror source must be another declared, enabled output that does not itself mirror";
        }
        {
          assertion = lib.all
            (src:
              let rs = lib.filter (r: r.mirror == src.output) mirrored;
              in lib.all (r: r.width == (lib.head rs).width && r.height == (lib.head rs).height) rs)
            (lib.filter (s: lib.any (r: r.mirror == s.output) mirrored) candidates);
          message = msg "outputs mirroring the same source must share width and height (Mutter needs one mode size per logical monitor)";
        }
        {
          assertion = !usable || lib.all (p: !overlap p.a p.b) pairs;
          message = msg "enabled outputs must not overlap (positions are logical pixels: size divided by scale, swapped for 90/270)";
        }
      ];

      warnings =
        lib.optional (named != [ ] && bad != [ ])
          (msg "no /etc/xdg/monitors.xml written, outputs ${lib.concatStringsSep ", " (map (m: m.output) bad)} are incomplete (an enabled output needs width, height and refresh; every output needs vendor, product and serial, \"unknown\" without EDID)")
        ++ lib.optional (named != [ ] && bad == [ ] && candidates == [ ])
          (msg "no /etc/xdg/monitors.xml written, no enabled non-mirrored output is declared")
        ++ lib.optional (usable && !(lib.any (m: m.primary) candidates))
          (msg "no output has primary = true, using ${primaryOut}")
        ++ lib.optional (usable && lib.length (lib.filter (m: m.primary) candidates) > 1)
          (msg "several outputs have primary = true, using ${primaryOut}");

      environment.etc."xdg/monitors.xml" = lib.mkIf usable {
        text = monitorsXml primaryOut named;
      };
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      primaryWp = myconfig.constants.primaryWallpaper;
      useFallbackWp = primaryWp.wallpaperURL == "";
      wallpaperPath = pkgs.fetchurl {
        url = if useFallbackWp then myconfig.constants.fallbackWallpaperURL else primaryWp.wallpaperURL;
        sha256 = if useFallbackWp then myconfig.constants.fallbackWallpaperSHA256 else primaryWp.wallpaperSHA256;
      };
      colorScheme = if myconfig.constants.theme.polarity == "dark" then "prefer-dark" else "prefer-light";
      iconThemeName =
        if myconfig.constants.theme.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
    in
    {
      home.packages =
        (lib.optionals myconfig.constants.theme.catppuccin [
          (pkgs.catppuccin-gtk.override {
            accents = [ myconfig.constants.theme.catppuccinAccent ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = myconfig.constants.theme.catppuccinFlavor;
          })
        ])
        ++ [
          pkgs.hydrapaper
          pkgs.papirus-icon-theme
        ];

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = lib.mkForce colorScheme;
          icon-theme = iconThemeName;
        };

        "org/gnome/desktop/background" = {
          picture-uri = lib.mkForce "file://${wallpaperPath}";
          picture-uri-dark = lib.mkForce "file://${wallpaperPath}";
          picture-options = lib.mkForce "zoom";
        };

        "org/gnome/desktop/screensaver" = {
          picture-uri = lib.mkForce "file://${wallpaperPath}";
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };

        "org/gnome/shell" = lib.mkIf (cfg.pinnedApps != [ ]) { favorite-apps = cfg.pinnedApps; };
      };
    };
}
