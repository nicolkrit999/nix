{ delib
, lib
, pkgs
, ...
}:
let
  scrubTargets = config:
    let
      btrfsFs = lib.filter (fs: fs.fsType == "btrfs") (lib.attrValues config.fileSystems);
      byDevice = lib.groupBy (fs: toString fs.device) btrfsFs;
    in
    map (group: (lib.head group).mountPoint) (lib.attrValues byDevice);
in
delib.module {
  name = "common-configuration";

  nixos.always =
    { myconfig
    , ...
    }:
    {
      imports = [
        (
          { config, ... }:
          {
            services.btrfs.autoScrub = lib.mkIf (scrubTargets config != [ ]) {
              enable = true;
              fileSystems = scrubTargets config;
            };
          }
        )
      ];

      # ---------------------------------------------------------
      # HOST IDENTITY
      # ---------------------------------------------------------
      networking.hostName = myconfig.constants.hostname;

      # ---------------------------------------------------------
      # LOCALE & TIME
      # ---------------------------------------------------------
      time.timeZone = myconfig.constants.timeZone;
      i18n.defaultLocale = myconfig.constants.mainLocale;

      console = {
        useXkbConfig = true;
        font = "Lat2-Terminus16";
      };

      # Allow unfree packages globally (needed for drivers, code, etc.)
      nixpkgs.config.allowUnfree = true;

      # Root shells (sudo -s) get root's own HOME instead of inheriting the invoking user's dotfiles.
      security.sudo.extraConfig = "Defaults always_set_home";

      # ---------------------------------------------------------
      # SYSTEM PACKAGES & ENVIRONMENT
      # ---------------------------------------------------------
      environment = {
        systemPackages =
          with pkgs;
          [
            # --- CLI UTILITIES ---
            dix
            git
            git-lfs # Needed by GitHub Desktop and other GUI clients
            nixfmt
            nix-prefetch-scripts # Tools to get hashes for nix derivations (used in every shell modules)
            nix-init
            nix-tree
            nurl
            wget
            curl
            nodenv

            # --- SYSTEM TOOLS ---
            foot # Tiny, zero-config terminal (Rescue tool)
            gsettings-desktop-schemas
            libnotify # Used by most de/wm modules
            libsecret
            seahorse
            sops
            tpm2-tss # Used for hosts that installed using disko with luks

            # --- GRAPHICS & GUI SUPPORT ---
            gtk3
            qt5.qtwayland
            kdePackages.qtwayland
          ]
          ++ (with pkgs.kdePackages; [
            gwenview # Default image viewer as defined in mime.nix
          ]);

        extraInit = ''
          if [ -z "$SSH_AUTH_SOCK" ] && [ -n "$XDG_RUNTIME_DIR" ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
          fi
        '';

        variables.GTK_APPLICATION_PREFER_DARK_THEME =
          if myconfig.constants.theme.polarity == "dark" then "1" else "0";
      };

      # ---------------------------------------------------------
      # FONTS
      # ---------------------------------------------------------
      fonts = {
        packages = with pkgs; [
          nerd-fonts.jetbrains-mono # Primary family: mono, Mono and Propo (UI/sans/serif) variants
          nerd-fonts.symbols-only
          noto-fonts # Script fallback coverage ("no tofu"), not a primary UI font
          dejavu_fonts
          noto-fonts-lgc-plus
          noto-fonts-color-emoji
          noto-fonts-cjk-sans
          texlivePackages.hebrew-fonts
          font-awesome # System icons (Waybar/Bar)
          powerline-fonts # Shell prompt glyphs
          powerline-symbols # Terminal font glyphs
        ];
        fontconfig.enable = true;
      };

      # ---------------------------------------------------------
      # SECURITY & WRAPPERS
      # ---------------------------------------------------------
      services = {
        xserver.xkb = {
          layout = myconfig.constants.keyboardLayout;
          variant = myconfig.constants.keyboardVariant;
        };

        openssh = {
          enable = true;
          # tailnet-only: tailscale0 is trusted, so no public port 22
          openFirewall = false;
        };

        gnome = {
          # gnome-keyring is the ONLY Secret Service provider, unlocked via PAM.
          # See Documentation/usage/gotchas/secret-service-single-provider.md
          gnome-keyring.enable = true;
          # gcr-ssh-agent is the only SSH agent (gpg-agent SSH support is off)
          gcr-ssh-agent.enable = true;
        };
      };

      security = {
        rtkit.enable = true;

        # Polkit Rules: Realtime Audio Permissions
        polkit = {
          enable = true;
          extraConfig = ''
            polkit.addRule(function(action, subject) {
              if (subject.isInGroup("wheel")) {
                // Auto-approve realtime audio requests
                if (action.id == "org.freedesktop.RealtimeKit1.acquire-high-priority" ||
                    action.id == "org.freedesktop.RealtimeKit1.acquire-real-time") {
                  return polkit.Result.YES;
                }
              }
            });
          '';
        };

        pam.services = {
          login = {
            enableGnomeKeyring = true;
            kwallet.enable = lib.mkForce false;
          };
          sddm = {
            enableGnomeKeyring = true;
            kwallet.enable = lib.mkForce false;
          };
          kde.kwallet.enable = lib.mkForce false;
        };
      };

      programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

      # ---------------------------------------------------------
      # SYSTEM TWEAKS
      # ---------------------------------------------------------
      systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
    };
}
