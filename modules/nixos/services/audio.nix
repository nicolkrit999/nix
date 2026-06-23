{ delib, pkgs, ... }:
delib.module {
  name = "services.audio";

  options = with delib; moduleOptions {
    enable = boolOption true;
    clockRate = intOption 48000;
  };

  nixos.ifEnabled = { cfg, ... }: {
    # nixpkgs 26.05 regression (commit 3426825): ffado pulls in i686-linux builder.pl;
    # libcamera and roc-toolkit both pull in a scons/numpy/openblas chain that requests
    # an i686-linux build on x86_64-linux hosts. None of these features are used here
    # (no FireWire, libcamera, or ROC network-audio hardware). Overlay replaces every
    # pkgs.pipewire reference system-wide.
    nixpkgs.overlays = [
      (_final: prev: {
        # nixpkgs 26.05 regression (commit 3426825): libcamera = null is wrong - availableOn
        # returns true for null (null.meta.platforms falls back to lib.platforms.all via `or`),
        # so meson still gets -Dlibcamera=true and tries a wrap download, which fails in the
        # nix sandbox. Use overrideAttrs to remove libcamera from buildInputs and flip the flag.
        pipewire = (prev.pipewire.override {
          ffadoSupport = false;
          rocSupport = false;
        }).overrideAttrs (old: {
          buildInputs = builtins.filter (x: x != prev.libcamera) (old.buildInputs or [ ]);
          mesonFlags = builtins.filter (f: f != "-Dlibcamera=enabled") (old.mesonFlags or [ ])
            ++ [ "-Dlibcamera=disabled" ];
        });
        # nixpkgs 26.05 regression: wireplumber 0.5.14 docs build fails - Doxygen produces
        # empty index.xml causing sphinx/breathe to crash. Disable docs until upstream fixes.
        wireplumber = prev.wireplumber.overrideAttrs (old: {
          mesonFlags = builtins.filter (f: f != "-Ddoc=enabled") (old.mesonFlags or [ ])
            ++ [ "-Ddoc=disabled" ];
        });
      })
    ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = false; # workaround: overlay changes i686 pipewire hash, not in cache, no extra-platforms
      pulse.enable = true;

      # Low Latency Config
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = cfg.clockRate;
          "default.clock.quantum" = 1024;
        };
      };

      # Pulse Audio Compatibility
      extraConfig.pipewire-pulse."99-no-flat-volume" = {
        "pulse.properties" = {
          "pulse.min.quantum" = "1024/${toString cfg.clockRate}";
          "pulse.flat-volume" = false;
        };
      };

      # Stabilizes Optical/Digital Audio
      wireplumber.extraConfig = {
        "99-optical-fix" = {
          "monitor.alsa.rules" = [
            {
              "matches" = [
                { "node.name" = "~.*SPDIF.*"; }
                { "node.name" = "~.*optical.*"; }
                { "node.name" = "~.*iec958.*"; }
                { "node.name" = "~.*digital-stereo.*"; }
              ];
              "actions" = {
                "update-props" = {
                  "api.alsa.soft-mixer" = true;
                  "api.alsa.ignore-dB" = true;
                };
              };
            }
          ];
        };
      };
    };
    environment.systemPackages = with pkgs; [
      pipewire
      wireplumber
      wiremix
    ];
  };
}
