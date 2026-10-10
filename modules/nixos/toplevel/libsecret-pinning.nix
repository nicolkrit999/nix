{ delib, ... }:
let
  flag = "--password-store=gnome-libsecret";

  # Chromium/Electron auto-detect the password backend from XDG_CURRENT_DESKTOP,
  # which splits safe-storage keys across sessions. Pin every app to libsecret
  # (gnome-keyring, the single Secret Service provider).
  passwordStoreOverlay = final: prev:
    let
      # Wrapper for packages without a commandLineArgs override. Desktop files
      # are copied so absolute Exec= store paths point at the wrapper.
      wrap = pkg:
        let
          bin = pkg.meta.mainProgram or (final.lib.getName pkg);
        in
        final.symlinkJoin {
          inherit (pkg) name;
          paths = [ pkg ];
          nativeBuildInputs = [ final.makeWrapper ];
          postBuild = ''
            rm "$out/bin/${bin}"
            makeWrapper ${pkg}/bin/${bin} "$out/bin/${bin}" --add-flags "${flag}"
            for f in "$out"/share/applications/*.desktop; do
              [ -e "$f" ] || continue
              if grep -q "${pkg}" "$f"; then
                cp --remove-destination "$(readlink -f "$f")" "$f"
                substituteInPlace "$f" --replace-quiet "${pkg}" "$out"
              fi
            done
          '';
          meta = pkg.meta or { };
          passthru = (pkg.passthru or { }) // final.lib.optionalAttrs (pkg ? override) {
            override = args: wrap (pkg.override args);
          };
        };
    in
    {
      passwordStoreWrap = wrap;

      brave = prev.brave.override { commandLineArgs = flag; };
      chromium = prev.chromium.override { commandLineArgs = flag; };
      google-chrome = prev.google-chrome.override { commandLineArgs = flag; };
      vscode = prev.vscode.override { commandLineArgs = flag; };

      signal-desktop = wrap prev.signal-desktop;
      vesktop = wrap prev.vesktop;
      teams-for-linux = wrap prev.teams-for-linux;
      proton-pass = wrap prev.proton-pass;
      drawio = wrap prev.drawio;
      xmind = wrap prev.xmind;
      whatsapp-electron = wrap prev.whatsapp-electron;
      github-desktop = wrap prev.github-desktop;
      insomnia = wrap prev.insomnia;
    };
in
delib.module {
  name = "password-store";

  nixos.always.nixpkgs.overlays = [ passwordStoreOverlay ];
  home.always.nixpkgs.overlays = [ passwordStoreOverlay ];
}
