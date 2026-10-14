{ lib }:
let
  # sRGB channel (0..255) to linear light, same function contrast.py uses
  linTable = [
    0.0
    0.0003035269835488375
    0.000607053967097675
    0.0009105809506465125
    0.00121410793419535
    0.0015176349177441874
    0.001821161901293025
    0.0021246888848418626
    0.0024282158683907
    0.0027317428519395373
    0.003035269835488375
    0.003346535763899161
    0.003676507324047436
    0.004024717018496307
    0.004391442037410293
    0.004776953480693729
    0.005181516702338386
    0.005605391624202723
    0.006048833022857054
    0.006512090792594475
    0.006995410187265387
    0.007499032043226175
    0.008023192985384994
    0.008568125618069307
    0.009134058702220787
    0.00972121732023785
    0.010329823029626936
    0.010960094006488246
    0.011612245179743885
    0.012286488356915872
    0.012983032342173012
    0.013702083047289686
    0.014443843596092545
    0.01520851442291271
    0.01599629336550963
    0.016807375752887384
    0.017641954488384078
    0.018500220128379697
    0.019382360956935723
    0.0202885630566524
    0.021219010376003555
    0.02217388479338738
    0.02315336617811041
    0.024157632448504756
    0.02518685962736163
    0.026241221894849898
    0.027320891639074894
    0.028426039504420793
    0.0295568344378088
    0.030713443732993635
    0.03189603307301153
    0.033104766570885055
    0.03433980680868217
    0.03560131487502034
    0.03688945040110004
    0.0382043715953465
    0.03954623527673284
    0.04091519690685319
    0.042311410620809675
    0.043735029256973465
    0.04518620438567554
    0.046665086336880095
    0.04817182422688942
    0.04970656598412723
    0.05126945837404324
    0.052860647023180246
    0.05448027644244237
    0.05612849004960009
    0.05780543019106723
    0.0595112381629812
    0.06124605423161761
    0.06301001765316767
    0.06480326669290577
    0.06662593864377289
    0.06847816984440017
    0.07036009569659588
    0.07227185068231748
    0.07421356838014963
    0.07618538148130785
    0.07818742180518633
    0.08021982031446832
    0.0822827071298148
    0.08437621154414882
    0.08650046203654976
    0.08865558628577294
    0.09084171118340768
    0.09305896284668745
    0.0953074666309647
    0.09758734714186246
    0.09989872824711389
    0.10224173308810132
    0.10461648409110419
    0.10702310297826761
    0.10946171077829933
    0.1119324278369056
    0.11443537382697373
    0.11697066775851084
    0.11953842798834562
    0.12213877222960187
    0.12477181756095049
    0.12743768043564743
    0.1301364766903643
    0.13286832155381798
    0.13563332965520566
    0.13843161503245183
    0.14126329114027164
    0.14412847085805777
    0.14702726649759498
    0.14995978981060856
    0.15292615199615017
    0.1559264637078274
    0.1589608350608804
    0.162029375639111
    0.1651321945016676
    0.16826940018969075
    0.1714411007328226
    0.17464740365558504
    0.17788841598362912
    0.18116424424986022
    0.184474994500441
    0.18782077230067787
    0.19120168274079138
    0.1946178304415758
    0.19806931955994886
    0.20155625379439707
    0.20507873639031693
    0.20863687014525575
    0.21223075741405523
    0.21586050011389926
    0.2195261997292692
    0.2232279573168085
    0.22696587351009836
    0.23074004852434915
    0.23455058216100522
    0.238397573812271
    0.24228112246555486
    0.24620132670783548
    0.25015828472995344
    0.25415209433082675
    0.2581828529215958
    0.26225065752969623
    0.26635560480286247
    0.2704977910130658
    0.27467731206038465
    0.2788942634768104
    0.2831487404299921
    0.2874408377269175
    0.29177064981753587
    0.2961382707983211
    0.3005437944157765
    0.3049873140698863
    0.30946892281750854
    0.31398871337571754
    0.31854677812509186
    0.32314320911295075
    0.3277780980565422
    0.33245153634617935
    0.33716361504833037
    0.3419144249086609
    0.3467040563550296
    0.35153259950043936
    0.3564001441459435
    0.3613067797835095
    0.3662525955988395
    0.3712376804741491
    0.3762621229909065
    0.38132601143253014
    0.386429433787049
    0.39157247774972326
    0.39675523072562685
    0.4019777798321958
    0.4072402119017367
    0.41254261348390375
    0.4178850708481375
    0.4232676699860717
    0.4286904966139066
    0.43415363617474895
    0.4396571738409188
    0.44520119451622786
    0.45078578283822346
    0.45641102318040466
    0.4620769996544071
    0.467783796112159
    0.47353149614800955
    0.4793201831008268
    0.4851499400560704
    0.4910208498478356
    0.4969329950608704
    0.5028864580325687
    0.5088813208549338
    0.5149176653765214
    0.5209955732043543
    0.5271151257058131
    0.5332764040105052
    0.5394794890121072
    0.5457244613701866
    0.5520114015120001
    0.5583403896342679
    0.5647115057049292
    0.5711248294648731
    0.5775804404296506
    0.5840784178911641
    0.5906188409193369
    0.5972017883637634
    0.6038273388553378
    0.6104955708078648
    0.6172065624196511
    0.6239603916750761
    0.6307571363461468
    0.6375968739940326
    0.6444796819705821
    0.6514056374198242
    0.6583748172794485
    0.665387298282272
    0.6724431569576875
    0.6795424696330938
    0.6866853124353135
    0.6938717612919899
    0.7011018919329731
    0.7083757798916868
    0.7156935005064807
    0.7230551289219693
    0.7304607400903537
    0.7379104087727308
    0.7454042095403874
    0.7529422167760779
    0.7605245046752924
    0.768151147247507
    0.7758222183174236
    0.7835377915261935
    0.7912979403326302
    0.799102738014409
    0.8069522576692516
    0.8148465722161012
    0.8227857543962835
    0.8307698767746546
    0.83879901174074
    0.846873231509858
    0.8549926081242338
    0.8631572134541023
    0.8713671191987972
    0.8796223968878317
    0.8879231178819663
    0.8962693533742664
    0.9046611743911496
    0.9130986517934192
    0.9215818562772946
    0.9301108583754237
    0.938685728457888
    0.9473065367331999
    0.9559733532492861
    0.9646862478944651
    0.9734452903984125
    0.9822505503331171
    0.9911020971138298
    1.0
  ];

  eps = 0.005;

  channel = h: i: lib.fromHexString (builtins.substring i 2 h);
  rgb = h: [ (channel h 1) (channel h 3) (channel h 5) ];

  lum = h:
    let v = map (n: builtins.elemAt linTable n) (rgb h);
    in 0.2126 * builtins.elemAt v 0 + 0.7152 * builtins.elemAt v 1 + 0.0722 * builtins.elemAt v 2;

  ratio = a: b:
    let
      la = lum a;
      lb = lum b;
      hi = if la > lb then la else lb;
      lo = if la > lb then lb else la;
    in
    (hi + 0.05) / (lo + 0.05);

  hex2 = n:
    let s = lib.toLower (lib.toHexString n);
    in if builtins.stringLength s == 1 then "0" + s else s;

  # percent p (0..100) of the way from a toward b
  mix = p: a: b:
    "#" + lib.concatStrings (lib.zipListsWith
      (x: y: hex2 ((x * (100 - p) + y * p + 50) / 100))
      (rgb a)
      (rgb b));

  best = bg: cands:
    builtins.foldl' (a: b: if ratio b bg > ratio a bg then b else a) (builtins.head cands) cands;

  readableOn = bg: min: cands:
    let ok = builtins.filter (c: ratio c bg >= min + eps) cands;
    in if ok != [ ] then builtins.head ok else best bg (cands ++ [ "#000000" "#ffffff" ]);

  # keep the accent hue: tint it toward black or white until it reaches min
  accentOn = bg: min: accent:
    let
      target = best bg [ "#000000" "#ffffff" ];
      steps = map (p: mix p accent target) (lib.range 10 90 ++ [ 100 ]);
    in
    readableOn bg min ([ accent ] ++ steps);

  mkTheme = c:
    let
      text = bg: intended:
        readableOn bg 4.5 ([ intended ] ++ builtins.filter (x: x != intended)
          [ c.base05 c.base06 c.base07 c.base04 c.base00 c.base01 ]);
      fg = {
        pill = text c.base01 c.base05;
        active = text c.base05 c.base00;
        hover = text c.base02 c.base05;
        crit = text c.base08 c.base00;
        tooltip = text c.base00 c.base05;
        tagEmpty = text c.base01 c.base04;
      };
    in
    {
      inherit fg;
      accent = accentOn c.base01 3;
      cssVariables =
        lib.concatMapStrings (n: "@define-color ${n} ${c.${n}};\n") [
          "base00"
          "base01"
          "base02"
          "base03"
          "base04"
          "base05"
          "base06"
          "base07"
          "base08"
          "base09"
          "base0A"
          "base0B"
          "base0C"
          "base0D"
          "base0E"
          "base0F"
        ]
        + lib.concatMapStrings (n: "@define-color fg_${n} ${fg.${n}};\n") [ "pill" "active" "hover" "crit" "tooltip" ];
    };

  mkWaybar = { pkgs, myconfig, colors }:
    let
      c = colors;
      t = mkTheme c;
      inherit (myconfig.constants) hostname mainLocale user;
      jq = "${pkgs.jq}/bin/jq";
      weather = lib.escapeURL myconfig.constants.weather;
    in
    {
      inherit c t jq;
      userHost = "${user}<span font_family='JetBrainsMono Nerd Font Propo'>󱄅</span>${hostname}";
      workspacesCss = builtins.readFile ./workspaces.css;

      bar = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 8;
        margin-bottom = 0;
        margin-left = 16;
        margin-right = 16;
      };

      modulesRight = language:
        [ language "custom/weather" "custom/wifi" "custom/bluetooth" "pulseaudio" "custom/mic" "battery" ]
        ++ lib.optional myconfig.services.coffee.enable "custom/coffee"
        ++ lib.optional myconfig.services.swaync.enable "custom/notification";

      modules = {
        "custom/weather" = {
          format = "{}";
          exec = "${lib.getExe pkgs.curl} -sf --max-time 10 'wttr.in/${weather}?format=%c%t' | sed 's/ //'";
          interval = 300;
          class = "weather";
          on-click = "${pkgs.xdg-utils}/bin/xdg-open \"https://wttr.in/${weather}\"";
        };

        "pulseaudio" = {
          format = "<span color='${t.accent c.base0D}'>{icon}</span> {volume}%";
          format-bluetooth = "<span color='${t.accent c.base0D}'>{icon}</span> {volume}%";
          format-muted = "<span color='${t.accent c.base08}'>󰖁</span> Muted";
          format-icons = {
            headphones = "󰋋";
            handsfree = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = lib.getExe pkgs.pavucontrol;
        };

        "custom/mic" = {
          format = "{}";
          exec = ''
            if ! wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1 \
              || wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
              echo "<span color='${t.accent c.base08}'>󰍭</span>"
            else
              echo "<span color='${t.accent c.base0B}'>󰍬</span>"
            fi
          '';
          interval = 1;
          on-click = "wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          tooltip = false;
        };

        "battery" = {
          states = { warning = 20; critical = 5; };
          format = "<span color='${t.accent c.base0A}'>{icon}</span> {capacity}%";
          format-charging = "<span color='${t.accent c.base0B}'>󰂄</span> {capacity}%";
          format-critical = "<span color='${t.fg.crit}'>{icon}</span> {capacity}% {time}";
          format-alt = "{time} <span color='${t.accent c.base0A}'>{icon}</span>";
          format-icons = [ "󰂎" "󰁻" "󰁾" "󰂀" "󰁹" ];
        };

        "custom/coffee" = {
          format = "{}";
          return-type = "json";
          exec = ''
            if ${pkgs.systemd}/bin/systemctl --user is-active --quiet coffee.service; then
              printf '{"text":"%s","class":"active","tooltip":"%s"}\n' "<span color='${t.accent c.base0F}'>󰅶</span>" "Coffee mode on: no automatic sleep, idle lock or lid action. Click to turn it off"
            else
              printf '{"text":"%s","class":"off","tooltip":"%s"}\n' "<span color='${t.accent c.base08}'>󰾪</span>" "Coffee mode off. Click to turn it on"
            fi
          '';
          on-click = "${myconfig.services.coffee.togglePackage}/bin/coffee-toggle";
          signal = 8;
          interval = 5;
        };

        "clock" = {
          locale = mainLocale;
          format = "<span color='${t.accent c.base0E}'></span> {:%I:%M %p}";
          format-alt = "<span color='${t.accent c.base0E}'></span> {:%m/%d/%Y - %I:%M %p}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
          };
        };

        "custom/notification" = {
          format = "{}";
          exec = ''
            swaync-client -swb 2>/dev/null \
              | ${jq} --unbuffered -r --arg on "<span color='${t.accent c.base09}'>󰂚</span>" \
                  'if (.text | tonumber) > 0 then "\($on) \(.text)" else "󰂜" end'
          '';
          restart-interval = 5;
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -C";
          tooltip = false;
        };

        "custom/wifi" = {
          format = "{}";
          exec = ''
            wifi_info=$(nmcli -t -f active,ssid dev wifi list --rescan no 2>/dev/null \
              | sed -n 's/^yes://p' | sed 's/\\:/:/g' | ${jq} -Rr '@html')
            if [ -n "$wifi_info" ]; then
              echo "<span color='${t.accent c.base0C}'>󰤨</span> $wifi_info"
            elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q "ethernet:connected"; then
              echo "<span color='${t.accent c.base0C}'>󰈀</span> ${hostname}"
            else
              echo "<span color='${t.fg.pill}'>󰤭</span> offline"
            fi
          '';
          interval = 5;
          on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
          tooltip = false;
        };

        "custom/bluetooth" = {
          format = "{}";
          exec = ''
            if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
              echo "<span color='${t.accent c.base0D}'>󰂯</span>"
            else
              echo "<span color='${t.fg.pill}'>󰂲</span>"
            fi
          '';
          interval = 5;
          tooltip = false;
        } // lib.optionalAttrs myconfig.bluetooth.enable {
          on-click = "blueman-manager";
        };
      };

      home = { name, title, enable, target, config, css, waybar ? pkgs.waybar }:
        let dir = "waybar-${name}";
        in
        {
          home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
          fonts.fontconfig.enable = true;

          xdg.configFile."${dir}/config" = lib.mkIf enable {
            text = builtins.toJSON config;
          };
          xdg.configFile."${dir}/style.css" = lib.mkIf enable {
            text = "${t.cssVariables}\n${builtins.readFile ./common-head.css}${css}${builtins.readFile ./common-tail.css}\n";
          };

          systemd.user.services.${dir} = lib.mkIf enable {
            Unit = {
              Description = "Waybar for ${title}";
              Documentation = "https://github.com/Alexays/Waybar/wiki";
              PartOf = [ target ];
              After = [ target ];
              ConditionEnvironment = "WAYLAND_DISPLAY";
            };
            Service = {
              ExecStart = "${waybar}/bin/waybar -c %h/.config/${dir}/config -s %h/.config/${dir}/style.css";
              ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
              Restart = "on-failure";
              RestartSec = 1;
              KillMode = "mixed";
            };
            Install = {
              WantedBy = [ target ];
            };
          };
        };
    };
in
{
  inherit mkTheme mkWaybar;
}
