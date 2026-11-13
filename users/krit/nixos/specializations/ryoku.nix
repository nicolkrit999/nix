{ delib
, inputs
, pkgs
, config
, options
, lib
, ...
}:
let
  c = config.myconfig.constants;
  polarity = c.theme.polarity;
  capPolarity = lib.toUpper (lib.substring 0 1 polarity) + lib.substring 1 (-1) polarity;
  dotfilesUrl = "https://github.com/nicolkrit999/dotfiles";
  nixRepoUrl = "https://github.com/nicolkrit999/nix";
  dotfilesPrivateUrl = "ssh://git@gitea-ssh.nicolkrit.ch:2222/krit/dotfiles-private.git";
  giteaKnownHost = "[gitea-ssh.nicolkrit.ch]:2222 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHCA8VQtkhSH0wg2Xvi5FjIofM4XMo/+PrFVFdVnu/wC";

  mkOff = paths: lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) paths
    )
  );

  # Full working copy at ~/<dir>: clone when missing, otherwise fast-forward only a clean, fully pushed
  # checkout. Never resets or discards (the user commits here, and Claude writes memory through the
  # dotfiles-private links). A shallow single-branch checkout from an older clone is healed first.
  # sshKey: private repo over SSH with that key and the pinned Gitea host key on port 2222; null: public https.
  mkRepoSync = pkgs: { name, description, dir, url, sshKey ? null }:
    let
      git = "${pkgs.git}/bin/git";
      coreutils = "${pkgs.coreutils}/bin";
      knownHosts = pkgs.writeText "ryoku-gitea-known-hosts" "${giteaKnownHost}\n";
    in
    {
      Unit = {
        Description = description;
        StartLimitIntervalSec = 0;
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "30s";
        Environment = [ "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" ];
        ExecStart = pkgs.writeShellScript name ''
          set -u
          dir="$HOME/${dir}"
          export GIT_TERMINAL_PROMPT=0
          ${lib.optionalString (sshKey != null) ''
            key="$HOME/${sshKey}"
            if [ ! -r "$key" ]; then
              echo "${name}: $key is not readable yet" >&2
              exit 1
            fi
            export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${knownHosts}"
          ''}
          if [ -d "$dir/.git" ]; then
            if [ "$(${git} -C "$dir" rev-parse --is-shallow-repository)" = true ]; then
              ${git} -C "$dir" fetch --quiet --unshallow origin || exit 1
            fi
            ${git} -C "$dir" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
            ${git} -C "$dir" fetch --quiet origin || exit 1
            if [ -n "$(${git} -C "$dir" status --porcelain)" ]; then
              echo "${name}: work tree has local changes, not updating" >&2
              exit 0
            fi
            ahead=$(${git} -C "$dir" rev-list --count '@{u}..HEAD' 2>/dev/null) || exit 0
            if [ "$ahead" != 0 ]; then
              echo "${name}: unpushed commits, not updating" >&2
              exit 0
            fi
            ${git} -C "$dir" merge --quiet --ff-only '@{u}' || exit 1
          elif [ -e "$dir" ]; then
            echo "${name}: $dir exists but is not a git checkout, leaving it alone" >&2
            exit 1
          else
            tmp=$(${coreutils}/mktemp -d "$HOME/.${name}.XXXXXX")
            trap '${coreutils}/rm -rf "$tmp"' EXIT
            ${git} clone --quiet ${url} "$tmp/repo" || exit 1
            [ -e "$dir" ] || ${coreutils}/mv "$tmp/repo" "$dir"
          fi
        '';
      };
    };

  personalOff = mkOff [
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
  ];

  hypridle = config.myconfig.services.hypridle;
  # Suspend has no stage in hypridle; these are Ryoku's own defaults (15 min on battery, 30 on AC). mkDefault so a host can override
  # (the desktop never suspends).
  idleStages = suspendSec: {
    dimSec = hypridle.dimTimeout;
    lockSec = hypridle.lockTimeout;
    screenOffSec = hypridle.screenOffTimeout;
    suspendSec = lib.mkDefault suspendSec;
  };

  hasPath = path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options;
in
delib.module {
  name = "krit.specializations.ryoku";

  nixos.always = lib.mkIf config.myconfig.specializations.ryoku.enable {
    myconfig.specializations.ryoku.sddmCursorTheme = "Bibata-Modern-Ice";
    myconfig.specializations.ryoku.sddmCursorPackage = pkgs.bibata-cursors;

    myconfig.specializations.ryoku.settings = {
      # AC: performance. On battery Ryoku's auto switch drops to Power Saver and restores the profile on AC, and Power Saver
      # is redefined as the middle ground (it would otherwise be the strictest profile).
      power-profile.profile = "performance";
      performance.autoPowerSaverOnBattery = true;
      power = {
        profiles.power-saver = {
          governor = "powersave";
          epp = "balance_power";
          maxFreqPct = 90;
        };
        # Dim, lock and screen off follow the normal profile's hypridle; suspend is Ryoku's own.
        idle = {
          enabled = true;
          onDesktops = true;
          battery = idleStages 900;
          ac = idleStages 1800;
        };
      };
      desktop = {
        desktop.appearance = {
          gapsIn = 6;
          gapsOut = 12;
          rounding = 4;
        };
        desktop.input = {
          middleEmulation = true;
          workspaceSwipe = true;
        };
        wm.hyprland.dwindle.preserveSplit = true;
      };
      shell = {
        fontFamily = "JetBrainsMono Nerd Font Mono";
        deckFrost = 0.5;
        barStyle = "orpheus";
        clipboard.pruneWeekly = true;
        general.temperature_unit = "Metric";
        theme = {
          theme = "Dracula";
          matugen = {
            contrast = 0;
            mode = capPolarity;
            preference = "Darkness";
            scheme_type = "Expressive";
          };
        };
      };
      launcher = {
        bgBlur = 8;
        heroStrength = 0.3786;
        showGreeting = false;
        heroImage = "file://${config.myconfig.specializations.ryoku.home}/Pictures/Wallpapers/wallhaven-vpyrm5.jpg";
      };
      matugen = {
        mode = polarity;
        schemeType = "scheme-expressive";
        contrast = 0;
        prefer = "darkness";
      };
      ryogami = {
        theme = {
          policy = "fixed";
          staticTheme = "Dracula";
        };
        matugen.mode = polarity;
        wallpaperMute = true;
        transition = {
          durationMs = 900;
          enabled = true;
          shader = "random";
        };
        overviewBackdrop = {
          blur = 45;
          blurEnabled = true;
          dim = 0;
          enabled = true;
          followWallpaper = true;
        };
        components.wallpaperSelector.displayMode = "slices";
      };
    };

    specialisation.ryoku.configuration = { config, ... }:
      let
        user = config.myconfig.constants.user;
      in
      {
        imports = [
          personalOff
          (lib.optionalAttrs (hasPath [ "services" "external" "dotfiles" "wallpapersLink" ]) {
            myconfig.services.external.dotfiles.wallpapersLink = lib.mkForce false;
          })
        ];

        home-manager.users.${user} = { pkgs, ... }: {
          # Wins over Ryoku's ryoku-fastfetch in PATH (/etc/profiles/per-user precedes /run/current-system/sw) for the bash, zsh and
          # fish greetings alike. Image protocols do not pass through multiplexers (the chafa branch hangs panes), so outside a plain
          # kitty or ghostty window the Hub-chosen emblem is rendered once to a text sprite and shown as a file-raw logo.
          home.packages = [
            (pkgs.writeShellScriptBin "ryoku-fastfetch" ''
              real=${inputs.ryoku.packages.${pkgs.stdenv.hostPlatform.system}.ryoku-desktop-data}/bin/ryoku-fastfetch
              if { [ -n "''${KITTY_WINDOW_ID:-}" ] || [ "''${TERM:-}" = xterm-kitty ] || [ "''${TERM:-}" = xterm-ghostty ] || [ "''${TERM_PROGRAM:-}" = ghostty ]; } && [ -z "''${TMUX:-}" ]; then
                exec "$real" "$@"
              fi
              cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
              logo=()
              if [ -r "$cfg" ]; then
                json=$(${pkgs.gnused}/bin/sed 's#^[[:space:]]*//.*$##' "$cfg")
                src=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.source // empty' 2>/dev/null)
                w=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.width // 28' 2>/dev/null)
                h=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.height // 14' 2>/dev/null)
                type=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.type // empty' 2>/dev/null)
                # Only image logos need the multiplexer workarounds below. Builtin, text, command and none logos print fine
                # anywhere, so they go to the real wrapper untouched; an auto logo without a source is the builtin one.
                case "$type" in
                  kitty-direct|kitty|kitty-icat|sixel|iterm|chafa) ;;
                  auto|"") [ -n "$src" ] || exec "$real" "$@" ;;
                  *) exec "$real" "$@" ;;
                esac
                case "$src" in "~/"*) src="$HOME/''${src#\~/}" ;; esac
                if [ -n "$src" ] && [ -r "$src" ] && [ -n "''${TMUX:-}" ] && [ "$(${pkgs.tmux}/bin/tmux display-message -p '#{client_termname}' 2>/dev/null)" = xterm-kitty ]; then
                  # kitty behind tmux: the real image through tmux passthrough as unicode placeholders, drawn as ordinary text cells.
                  # The upload (cached, resent every run since kitty forgets it on restart) and the placeholder rows are split apart
                  # because icat's own rows carry cursor movement that breaks fastfetch's side-by-side layout.
                  pdir="''${XDG_CACHE_HOME:-$HOME/.cache}/ryoku"
                  pkey=$(printf '%s' "ph1 $src $(${pkgs.coreutils}/bin/stat -c '%Y %s' "$src") $w $h" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
                  up="$pdir/fastfetch-ph-$pkey.upload"
                  rows="$pdir/fastfetch-ph-$pkey.rows"
                  cols="$pdir/fastfetch-ph-$pkey.cols"
                  if [ ! -s "$up" ] || [ ! -s "$rows" ] || [ ! -s "$cols" ]; then
                    ${pkgs.coreutils}/bin/mkdir -p "$pdir"
                    raw=$(${pkgs.coreutils}/bin/mktemp "$pdir/ph.XXXXXX")
                    small=$(${pkgs.coreutils}/bin/mktemp "$pdir/ph.XXXXXX.png")
                    if ${pkgs.imagemagick}/bin/magick "$src" -background '#282a36' -alpha remove -alpha off -resize 360x png:"$small" 2>/dev/null \
                      && ${pkgs.kitty}/bin/kitten icat --unicode-placeholder --passthrough tmux --transfer-mode=stream --place "''${w}x''${h}@0x0" --align left "$small" > "$raw" 2>/dev/null \
                      && [ -s "$raw" ]; then
                      ${pkgs.perl}/bin/perl -0777 -e '
                        open F, "<$ARGV[0]"; $_ = <F>; close F;
                        my @u = /(\ePtmux;.*?\e\e\\\e\\)/sg;
                        (my $r = $_) =~ s/\ePtmux;.*?\e\e\\\e\\//sg;
                        my ($cols) = ($u[0] // "") =~ /,c=(\d+),/;
                        $r =~ s/\e7//g; $r =~ s/\e8//g; $r =~ s/\e\[\d*;?\d*H//g; $r =~ s/\e\[\d*C//g; $r =~ s/\r//g;
                        my ($c, $o) = ("", "");
                        for (split /\n/, $r) {
                          next unless length;
                          if (/^(\e\[38:2:\d+:\d+:\d+m)/) { $c = $1 } else { $_ = $c . $_ }
                          s/\e\[39m$//;
                          $o .= $_ . "\e[39m\n";
                        }
                        exit 1 unless @u && $cols && length $o;
                        open U, ">$ARGV[1]"; print U join("", @u); close U;
                        open R, ">$ARGV[2]"; print R $o; close R;
                        open W, ">$ARGV[3]"; print W $cols; close W;
                      ' "$raw" "$up" "$rows" "$cols" || ${pkgs.coreutils}/bin/rm -f "$up" "$rows" "$cols"
                    fi
                    ${pkgs.coreutils}/bin/rm -f "$raw" "$small"
                  fi
                  if [ -s "$up" ] && [ -s "$rows" ] && [ -s "$cols" ]; then
                    ${pkgs.tmux}/bin/tmux set -p allow-passthrough on 2>/dev/null
                    ${pkgs.coreutils}/bin/cat "$up"
                    # fastfetch counts every placeholder cell as two columns wide, so as a file-raw logo it pushes the header and the
                    # values too far right. It prints the info alone instead and the image rows are merged beside it here.
                    lp=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.padding.left // 0' 2>/dev/null)
                    rp=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.padding.right // 3' 2>/dev/null)
                    tp=$(printf '%s' "$json" | ${pkgs.jq}/bin/jq -r '.logo.padding.top // 0' 2>/dev/null)
                    "$real" --logo-type none --logo-padding-left 0 --logo-padding-right 0 --logo-padding-top 0 --pipe false "$@" \
                      | ${pkgs.perl}/bin/perl -e '
                        my ($rf, $lp, $rp, $tp, $w) = @ARGV;
                        open R, "<$rf"; chomp(my @r = <R>); close R;
                        my $i = 0;
                        while (<STDIN>) {
                          chomp;
                          my $row = ($i >= $tp && $i - $tp < @r) ? $r[$i - $tp] : (" " x $w);
                          print " " x $lp, $row, " " x $rp, $_, "\n";
                          $i++;
                        }
                        while ($i - $tp < @r) { print " " x $lp, $r[$i - $tp], "\n"; $i++ }
                      ' "$rows" "$lp" "$rp" "$tp" "$(${pkgs.coreutils}/bin/cat "$cols")"
                    exit 0
                  fi
                fi
                if [ "''${#logo[@]}" -eq 0 ] && [ -n "$src" ] && [ -r "$src" ]; then
                  key=$(printf '%s' "flat2 $src $(${pkgs.coreutils}/bin/stat -c '%Y %s' "$src") $w $h" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
                  cache="''${XDG_CACHE_HOME:-$HOME/.cache}/ryoku/fastfetch-logo-$key.txt"
                  if [ ! -s "$cache" ]; then
                    ${pkgs.coreutils}/bin/mkdir -p "''${cache%/*}"
                    tmp=$(${pkgs.coreutils}/bin/mktemp "$cache.XXXXXX")
                    if ${pkgs.imagemagick}/bin/magick "$src" -background '#282a36' -alpha remove -alpha off png:- 2>/dev/null | ${pkgs.chafa}/bin/chafa --format symbols --size "''${w}x''${h}" --animate off --polite on - > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
                      ${pkgs.coreutils}/bin/mv -f "$tmp" "$cache"
                    else
                      ${pkgs.coreutils}/bin/rm -f "$tmp"
                    fi
                  fi
                  if [ -s "$cache" ]; then
                    logo=(--logo "$cache" --logo-type file-raw)
                  fi
                fi
              fi
              if [ "''${#logo[@]}" -eq 0 ]; then
                logo=(--logo-type none)
              fi
              exec "$real" "''${logo[@]}" "$@"
            '')
          ];

          systemd.user.services = {
            ryoku-dotfiles-sync = mkRepoSync pkgs {
              name = "ryoku-dotfiles-sync";
              description = "Clone or update the public dotfiles into ~/dotfiles (nvim config link target)";
              dir = "dotfiles";
              url = dotfilesUrl;
            };
            ryoku-dotfiles-private-sync = mkRepoSync pkgs {
              name = "ryoku-dotfiles-private-sync";
              description = "Clone or fast-forward the private dotfiles into ~/dotfiles-private (Claude config and memory links)";
              dir = "dotfiles-private";
              url = dotfilesPrivateUrl;
              sshKey = ".ssh/id_github";
            };
            ryoku-nix-sync = mkRepoSync pkgs {
              name = "ryoku-nix-sync";
              description = "Clone or update the public nix repo into ~/${c.flakeDir}";
              dir = c.flakeDir;
              url = nixRepoUrl;
            };
          };
        };
      };
  };
}
