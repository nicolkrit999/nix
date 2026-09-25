# Intel IPU7 (Panther Lake) webcam support: hardware.ipu7 + the ipu7-drivers
# kernel module + the userspace camera stack aren't available on nixos-26.05
# yet, only on nixos-unstable. Rather than importing unstable's prebuilt
# packages wholesale (which would mix a foreign GStreamer plugin ABI into a
# process otherwise loading stable-built GStreamer core), this module pulls
# only the *recipes* from nixpkgs-unstable's source tree and builds them
# against our own stable `pkgs` and our own kernelPackages, so everything
# that ends up loaded together at runtime is compiled against one channel.
#
# See ~/.claude memory "nixos-laptop-panther-lake-hardware-issues" for the
# full hardware background (camera IPU at PCI 0000:00:05.0, sensor ov08x40).
{ delib
, pkgs
, lib
, inputs
, ...
}:
delib.module {
  name = "krit.services.laptop.camera";
  options = delib.singleEnableOption false;

  # `hardware.ipu7` doesn't exist on our nixos-26.05 channel yet, so import
  # its module straight from the nixpkgs-unstable flake input's source tree.
  # This only declares the option; it stays inert until enabled below.
  nixos.always = {
    imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/hardware/video/webcam/ipu7.nix" ];
  };

  nixos.ifEnabled =
    { ... }:
    let
      unstableSrc = inputs.nixpkgs-unstable;
    in
    {
      nixpkgs.overlays = [
        (final: prev: {
          # Firmware/image-processing blobs (proprietary, unfree, no binary
          # cache - built locally). No kernel dependency, safe to build
          # straight against our stable pkgs.
          ipu7-camera-bins = final.callPackage "${unstableSrc}/pkgs/by-name/ip/ipu7-camera-bins/package.nix" { };
          ivsc-firmware = final.callPackage "${unstableSrc}/pkgs/by-name/iv/ivsc-firmware/package.nix" { };

          # Userspace HAL for the Panther Lake variant (ipu75xa). Same recipe
          # as ipu7x-camera-hal, just built with ipuVersion = "ipu75xa" -
          # mirrors how nixpkgs itself derives `ipu75xa-camera-hal`.
          ipu75xa-camera-hal = final.callPackage "${unstableSrc}/pkgs/by-name/ip/ipu7x-camera-hal/package.nix" {
            ipuVersion = "ipu75xa";
          };

          # GStreamer source plugin, built inside our OWN gst_all_1 scope so
          # it links against our own gst-plugins-base/gstreamer, not
          # unstable's - this is what avoids the ABI mismatch.
          gst_all_1 = prev.gst_all_1.overrideScope (gfinal: gprev: {
            icamerasrc-ipu75xa = gfinal.callPackage "${unstableSrc}/pkgs/development/libraries/gstreamer/icamerasrc" {
              ipuVariant = "ipu7";
              ipu7x-camera-hal = final.ipu75xa-camera-hal;
              # Unused when ipuVariant = "ipu7", but the recipe still takes it
              # as a formal argument - short-circuit it instead of requiring
              # stable pkgs to already carry an `ipu6-camera-hal` attribute.
              ipu6-camera-hal = null;
            };
          });
        })
      ];

      # ipu7-drivers (out-of-tree PSys kernel module, not upstream/mainline
      # yet) is a plain `{ kernel, kernelModuleMakeFlags, ... }` derivation
      # with no unstable-specific dependencies and only a `kernel >= 6.12`
      # floor (confirmed via nixpkgs source) - well under our linux_testing
      # 7.3-rc4. Extend OUR OWN kernelPackages (the exact set kernel.nix
      # already selects for this host) rather than pulling in one of
      # unstable's own prebuilt kernel package sets. mkForce is required here
      # only because kernel.nix's plain assignment and this one would
      # otherwise conflict at equal priority - kernel.nix itself is untouched
      # and this still resolves to the same base kernelPackages it selects.
      boot.kernelPackages = lib.mkForce (
        pkgs.linuxKernel.packages.linux_testing.extend (kfinal: kprev: {
          ipu7-drivers = kfinal.callPackage "${unstableSrc}/pkgs/os-specific/linux/ipu7-drivers" { };
        })
      );

      boot.kernelModules = [ "intel_ipu7_psys" ];

      hardware.ipu7 = {
        enable = true;
        platform = "ipu75xa";
      };

      # Tuning ported from another config for the same laptop/sensor
      # (ov08x40-uf). hardware.ipu7's own module already wires
      # services.v4l2-relayd.instances.ipu7 with generic defaults; override
      # the pipeline/label/resolution for this specific sensor.
      services.v4l2-relayd.instances.ipu7 = {
        cardLabel = "Built-in Front Camera (Intel ISP)";
        input = {
          pipeline = lib.mkForce "icamerasrc device-name=ov08x40-uf sharpness=80 ev=-1 saturation=10";
          width = 3840;
          height = 2160;
          framerate = 30;
        };
        output.format = "NV12";
      };

      systemd.services.v4l2-relayd-ipu7 = {
        after = [ "systemd-modules-load.service" ];
        serviceConfig.RuntimeDirectory = "camera";
        serviceConfig.RestartSec = "3s";
        # exclusive_caps exposes capture only once the relay opens its writer.
        # Refresh udev's capabilities then, so an existing desktop finds the camera.
        postStart = ''
          device=$(cat "$V4L2_DEVICE_FILE")
          for attempt in $(seq 1 50); do
            if ${pkgs.v4l-utils}/bin/v4l2-ctl -d "$device" --get-fmt-video >/dev/null 2>&1; then
              ${pkgs.systemd}/bin/udevadm trigger --action=change "/sys/class/video4linux/$(basename "$device")"
              exit 0
            fi
            sleep 0.1
          done
          echo "Camera relay did not expose a capture format" >&2
          exit 1
        '';
      };

      # Release the HAL before suspend and reopen it after resume, without
      # unloading the CVS driver or disrupting the sensor's media graph.
      systemd.services.camera-sleep = {
        wantedBy = [ "sleep.target" ];
        before = [ "sleep.target" ];
        unitConfig.StopWhenUnneeded = true;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.systemd}/bin/systemctl stop v4l2-relayd-ipu7.service";
          ExecStop = "${pkgs.systemd}/bin/systemctl --no-block start v4l2-relayd-ipu7.service";
        };
      };

      # Avoid two camera stacks competing for the same sensor. Browsers see
      # the processed V4L2 loopback feed; USB cameras remain available
      # through V4L2.
      services.pipewire.wireplumber.extraConfig."10-camera" = {
        "wireplumber.profiles".main."monitor.libcamera" = "disabled";
      };

      # Hide unprocessed Bayer capture nodes from desktop applications. The
      # root relay can still access them. Do not use WirePlumber's
      # device.disabled rule: it can deadlock audio discovery in some
      # WirePlumber versions.
      services.udev.packages = [
        (pkgs.writeTextDir "lib/udev/rules.d/71-ipu7-hide-isys.rules" ''
          SUBSYSTEM=="video4linux", ATTR{name}=="Intel IPU7 ISYS Capture *", TAG-="uaccess", TAG-="seat", MODE="0600", GROUP="root"
        '')
      ];
    };
}
