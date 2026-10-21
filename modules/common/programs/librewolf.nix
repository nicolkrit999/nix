{ delib
, lib
, ...
}:
let
  profileMarker = "nixcfg.librewolf.profile";
in
delib.module {
  name = "programs.librewolf";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    # An option rather than a read of the merged programs.librewolf.profiles: stylix and the marker
    # are defined per profile name (recursion), and stylix's own prefs would leak into overrides.cfg.
    profileSettings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { default = { }; };
      description = ''
        LibreWolf profiles declared by this module: the attribute name is the profile
        name, the value its prefs. Every listed profile is created and styled by stylix.
        Once any profile carries prefs they are written to the profile's `user.js` and
        re-applied through `~/.librewolf/librewolf.overrides.cfg`, which is evaluated
        after the `pref()` calls of LibreWolf's own `mozilla.cfg` (those beat `user.js`).
        Everything else about a profile (id, search, extensions, ...) is set on
        `programs.librewolf.profiles.<name>` directly.
      '';
    };
  };

  myconfig.ifEnabled = { cfg, ... }: {
    stylix.targets.librewolf.profileNames = lib.attrNames cfg.profileSettings;
  };

  home.ifEnabled = { cfg, ... }:
    let
      withOverrides = lib.any (prefs: prefs != { }) (lib.attrValues cfg.profileSettings);

      settings = lib.mapAttrs
        (name: prefs: prefs // lib.optionalAttrs withOverrides { ${profileMarker} = name; })
        cfg.profileSettings;

      overridesCfg = ''
        var profile = getPref("${profileMarker}");
      '' + lib.concatStrings (lib.mapAttrsToList
        (name: prefs: ''
          if (profile === ${builtins.toJSON name}) {
          ${lib.concatStrings (lib.mapAttrsToList (k: v: "  pref(${builtins.toJSON k}, ${builtins.toJSON v});\n") prefs)}}
        '')
        settings);
    in
    {
      home.file.".librewolf/librewolf.overrides.cfg" = lib.mkIf withOverrides {
        text = overridesCfg;
      };

      programs.librewolf = {
        enable = true;
        profiles = lib.mapAttrs (_: prefs: { settings = prefs; }) settings;
      };
    };
}
