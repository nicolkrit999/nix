{ delib, inputs, pkgs, ... }:
let
  # Each entry is fetched from the Chrome Web Store, unpacked, and has its
  # public key injected into manifest.json so Chromium derives the canonical
  # CWS extension ID (instead of a path-based ID). Without this, our
  # ExtensionInstallAllowlist / ExtensionSettings rules — which are keyed by
  # CWS IDs — wouldn't match the actually-loaded extensions, breaking pinning
  # and producing a policy warning on startup.
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

  injectKeyScript = pkgs.writeText "helium-crx-inject-key.py" ''
    import base64, hashlib, io, json, os, shutil, struct, sys, zipfile

    crx_path, out_dir = sys.argv[1], sys.argv[2]
    data = open(crx_path, "rb").read()
    assert data[:4] == b"Cr24", "not a CRX file"
    version, header_size = struct.unpack("<II", data[4:12])
    assert version == 3, f"expected CRX3, got v{version}"
    header = data[12:12 + header_size]
    zip_data = data[12 + header_size:]

    def read_varint(buf, pos):
        result, shift = 0, 0
        while True:
            b = buf[pos]; pos += 1
            result |= (b & 0x7F) << shift
            if not (b & 0x80): return result, pos
            shift += 7

    def parse(buf, start, end):
        fields = {}
        pos = start
        while pos < end:
            tag, pos = read_varint(buf, pos)
            field_no, wire_type = tag >> 3, tag & 7
            if wire_type == 0:
                val, pos = read_varint(buf, pos)
            elif wire_type == 2:
                length, pos = read_varint(buf, pos)
                val, pos = buf[pos:pos + length], pos + length
            else:
                raise Exception(f"unsupported wire type {wire_type}")
            fields.setdefault(field_no, []).append(val)
        return fields

    # CrxFileHeader: field 2 = sha256_with_rsa proofs, field 3 = sha256_with_ecdsa
    # proofs, field 10000 = signed_header_data (SignedData.crx_id is field 1).
    # CWS CRXs include both a CWS signing key and the developer's key; we pick
    # the one whose SHA256 matches crx_id — that's the developer key, which
    # derives the canonical extension ID.
    header_fields = parse(header, 0, len(header))
    signed = parse(header_fields[10000][0], 0, len(header_fields[10000][0]))
    crx_id = signed[1][0]

    public_key = None
    for field_no in (2, 3):
        for proof_bytes in header_fields.get(field_no, []):
            pk = parse(proof_bytes, 0, len(proof_bytes))[1][0]
            if hashlib.sha256(pk).digest()[:16] == crx_id:
                public_key = pk
                break
        if public_key is not None:
            break
    assert public_key is not None, "no proof matches crx_id"
    public_key_b64 = base64.b64encode(public_key).decode()

    os.makedirs(out_dir, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(zip_data)) as zf:
        zf.extractall(out_dir)

    metadata = os.path.join(out_dir, "_metadata")
    if os.path.isdir(metadata):
        shutil.rmtree(metadata)

    manifest_path = os.path.join(out_dir, "manifest.json")
    manifest = json.loads(open(manifest_path, encoding="utf-8-sig").read())
    manifest["key"] = public_key_b64
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
  '';

  unpackCrxWithKey = spec: pkgs.runCommand "helium-ext-keyed-${spec.id}"
    {
      nativeBuildInputs = [ pkgs.python3 ];
      src = fetchCrx { inherit (spec) id hash; };
    } ''
    mkdir -p $out
    python3 ${injectKeyScript} "$src" "$out"
  '';

  keyedExtensions = map unpackCrxWithKey extensionSpecs;
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

      # We bypass the flake's `extensions` option (which uses --load-extension
      # without injecting the CWS public key, so Chromium picks path-derived
      # IDs). Instead we build keyed extensions ourselves above and pass them
      # via extraFlags, plus allowlist them by their true CWS IDs below.
      extensions = [ ];

      extraFlags = [
        "--load-extension=${pkgs.lib.concatMapStringsSep "," toString keyedExtensions}"
      ];

      extraPolicies = {
        BookmarkBarEnabled = false;

        # Homepage + new-tab — replaces the "New Tab Override" extension
        HomepageLocation = "https://kagi.com";
        HomepageIsNewTabPage = false;
        ShowHomeButton = true;
        NewTabPageLocation = "https://kagi.com";

        ExtensionInstallAllowlist = map (e: e.id) extensionSpecs;

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
        # helium.browser.layout = ?; # TODO: see memory — int enum for classic/compact/vertical, mapping unresolved
      };
    };
  };
}
