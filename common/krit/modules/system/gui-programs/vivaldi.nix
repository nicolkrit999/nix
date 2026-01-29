{
  pkgs,
  lib,
  vars,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      vivaldi = prev.vivaldi.override {
        commandLineArgs = "--password-store=gnome --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations";
      };
    })
  ];

  # 2. Allow Unfree & Codecs
  nixpkgs.config = {
    allowUnfree = true;
    vivaldi = {
      proprietaryCodecs = true;
      enableWideVine = true;
    };
  };

  # 3. System Install
  environment.systemPackages = [
    pkgs.vivaldi
  ];
}
