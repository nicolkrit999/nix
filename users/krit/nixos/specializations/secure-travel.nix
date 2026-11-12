{ delib
, lib
, config
, options
, ...
}:
let
  hasClaudeWrappers = options ? myconfig.krit.programs.claude-code-wrappers;
  hasNetworkTools = options ? myconfig.krit.services.network-tools;
  hasPrinting = options ? myconfig.krit.services.printing;
  nasOff = lib.genAttrs
    (lib.filter (n: options ? myconfig.krit.services.nas.${n}) [
      "desktop-borg-backup"
      "laptop-borg-backup"
      "opencloud-mount"
      "smb"
      "sshfs"
    ])
    (_: { enable = lib.mkForce false; });

  hasKritProgram = n: options ? myconfig.krit.programs.${n};
  kritPrograms =
    lib.genAttrs
      (lib.filter hasKritProgram [ "pwas" "firefox" "chromium" "helium" "zen-browser" ])
      (_: { enable = lib.mkForce false; })
    // lib.optionalAttrs (hasKritProgram "librewolf") {
      librewolf.enable = lib.mkForce true;
    };
in
delib.module {
  name = "krit.specializations.secure-travel";

  nixos.always = lib.mkIf config.myconfig.specializations.secure-travel.enable {
    specialisation.secure-travel.configuration.imports =
      lib.optional hasClaudeWrappers
        {
          myconfig.krit.programs.claude-code-wrappers.enable = lib.mkForce false; # Bundles claude
        }
      ++ lib.optional (kritPrograms != { }) {
        myconfig.krit.programs = kritPrograms;
      }
      ++ lib.optional hasNetworkTools {
        # Packet capture and scanning tools (dumpcap wrapper, wireshark group) are attack surface in travel mode.
        myconfig.krit.services.network-tools.enable = lib.mkForce false;
      }
      ++ lib.optional hasPrinting {
        # Home printers are meaningless while travelling, and the NetworkManager dispatcher hook stays out of this profile.
        myconfig.krit.services.printing.enable = lib.mkForce false;
      }
      ++ lib.optional (nasOff != { }) {
        # I-09: the NAS consumers are tailnet-only and stay off in travel mode.
        myconfig.krit.services.nas = nasOff;
      };
  };
}
