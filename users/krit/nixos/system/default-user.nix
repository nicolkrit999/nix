{ delib, ... }:
delib.module {
  name = "krit.system.default-user";
  options.krit.system.default-user = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      users.mutableUsers = false;
      users.users.${myconfig.constants.user} = {
        isNormalUser = true;
        description = "${myconfig.constants.user}";
        extraGroups = [
          "wheel"
          "networkmanager"
          "input"
          "docker"
          "podman"
          "video"
          "audio"
        ];
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
      };
    };
}
