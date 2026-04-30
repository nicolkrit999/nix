{ delib, inputs, pkgs, ... }:
let
  # Each extension is fetched from CWS as a CRX, then served locally via a
  # self-hosted update manifest (file://). ExtensionInstallForcelist reads
  # the developer key out of the CRX header, so canonical CWS IDs apply
  # without unpacking. This persists install state in the profile, so
  # chrome.runtime.onInstalled fires once on real install — not on every
  # launch the way --load-extension did.
  extensionSpecs = [
    { id = "ghmbeldphafepmbegfdlkpapadhbakde"; hash = "sha256-I3IsZqbm/AlZwVd376/N1tZumBZQ6nh5q16EJnIlBV0="; } # Proton Pass
    { id = "nlipoenfbbikpbjkfpfillcgkoblgpmj"; hash = "sha256-KxcUkvIkkuh3s4hPy7asTucfP9znwtd8hF2WFQjCutk="; } # Awesome Screen Recorder & Screenshot
    { id = "chphlpgkkbolifaimnlloiipkdnihall"; hash = "sha256-LkQLIahNewg6u+1AM85s0Ln0XsPNdfyVgGS0YqTkPBc="; } # OneTab
    { id = "dphilobhebphkdjbpfohgikllaljmgbn"; hash = "sha256-IgmQYXUjBM0iONHXqTgcvIXihN2ZrXWCZsQZZg1xPxk="; } # SimpleLogin
    { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; hash = "sha256-nE5FE3Eo1jG8sT1KYjVl8JRbmAiyhN8IZObHsAIb0wY="; } # SponsorBlock
    { id = "lnaahdmijnjnmgaalacdgakieangpjgp"; hash = "sha256-xxdOTvjv9gaB1rS0bMsmrudydOGdTDtt73Ri+zRCpNQ="; } # Screenshot YouTube Video
    { id = "cdglnehniifkbagbbombnjghhcihifij"; hash = "sha256-weiUUUiZeeIlz/k/d9VDSKNwcQtmAahwSIHt7Frwh7E="; } # Kagi Search
    { id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; hash = "sha256-BnnCPisSxlhTSoQQeZg06Re8MhgwztRKmET9D93ghiw="; } # Kagi Summarizer
    { id = "ljipkdpcjbmhkdjjmbbaggebcednbbme"; hash = "sha256-wVSUhC4c24i4vpqeq1nZaeKtn32rn3+jorcC3WIaXJM="; } # Behind the Overlay
  ];

  fetchCrx = { id, hash }: pkgs.fetchurl {
    name = "${id}.crx";
    url = "https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=x64&os_arch=x86_64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=stable&prodversion=120.0.0.0&acceptformat=crx3&x=id%3D${id}%26installsource%3Dondemand%26uc";
    inherit hash;
  };

  readVersionScript = pkgs.writeText "helium-crx-read-version.py" ''
    import struct, sys, zipfile, io, json
    data = open(sys.argv[1], "rb").read()
    assert data[:4] == b"Cr24", "not a CRX"
    header_size = struct.unpack("<II", data[4:12])[1]
    zf = zipfile.ZipFile(io.BytesIO(data[12 + header_size:]))
    print(json.loads(zf.read("manifest.json").decode("utf-8-sig"))["version"])
  '';

  # Per-extension store path containing the CRX and a Chromium-format
  # update manifest (gupdate XML). ExtensionInstallForcelist points at
  # ${out}/updates.xml; codebase inside that XML is a file:// URL to the
  # CRX in the same store path.
  buildExtension = spec: pkgs.runCommand "helium-ext-${spec.id}"
    {
      nativeBuildInputs = [ pkgs.python3 ];
      src = fetchCrx { inherit (spec) id hash; };
    } ''
    mkdir -p $out
    cp $src $out/ext.crx
    version=$(python3 ${readVersionScript} "$src")
    cat > $out/updates.xml <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <gupdate xmlns="http://www.google.com/update2/response" protocol="2.0">
      <app appid="${spec.id}">
        <updatecheck codebase="file://$out/ext.crx" version="$version" />
      </app>
    </gupdate>
    EOF
  '';

  builtExtensions = map (spec: { inherit (spec) id; drv = buildExtension spec; }) extensionSpecs;
in
delib.module {
  name = "krit.programs.helium";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [ inputs.helium.nixosModules.helium ];
  };

  home.always = { ... }: {
    imports = [ inputs.helium.homeModules.helium ];
  };

  home.ifEnabled = { ... }: {
    programs.helium = {
      enable = true;
      defaultBrowser = false;
      extensions = [ ];

      extraFlags = [
        "--ozone-platform=auto"
        "--enable-features=PortalFileChooser"
      ];

      extraPolicies = {
        BookmarkBarEnabled = false;

        HomepageLocation = "https://kagi.com";
        HomepageIsNewTabPage = false;
        ShowHomeButton = true;
        NewTabPageLocation = "https://kagi.com";

        ExtensionInstallForcelist =
          map (e: "${e.id};file://${e.drv}/updates.xml") builtExtensions;

        # Whitelist file:// as an install source for the self-hosted CRXs.
        ExtensionInstallSources = [ "file:///*" ];

        # Pin the requested extensions. Left-to-right order is NOT
        # enforceable by policy (Chromium stores toolbar order in profile
        # Local State, not managed policies). Drag once after first launch;
        # desired order: OneTab → Behind the Overlay → Kagi Summarizer →
        # Proton Pass → SimpleLogin.
        ExtensionSettings = {
          "chphlpgkkbolifaimnlloiipkdnihall".toolbar_pin = "force_pinned"; # OneTab
          "ljipkdpcjbmhkdjjmbbaggebcednbbme".toolbar_pin = "force_pinned"; # Behind the Overlay
          "dpaefegpjhgeplnkomgbcmmlffkijbgp".toolbar_pin = "force_pinned"; # Kagi Summarizer
          "ghmbeldphafepmbegfdlkpapadhbakde".toolbar_pin = "force_pinned"; # Proton Pass
          "dphilobhebphkdjbpfohgikllaljmgbn".toolbar_pin = "force_pinned"; # SimpleLogin
        };
      };

      preferences = {
        browser.show_home_button = true;
        bookmark_bar.show_on_all_tabs = false;
      };
    };
  };
}
