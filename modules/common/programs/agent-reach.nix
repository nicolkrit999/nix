{ delib, pkgs, lib, ... }:
let
  py = pkgs.python3.pkgs;

  mkAgentReach = withCookies: py.toPythonApplication (py.buildPythonPackage rec {
    pname = "agent-reach";
    version = "1.5.0";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "Panniantong";
      repo = "Agent-Reach";
      tag = "v${version}";
      hash = "sha256-rCEtsGDa+CzEGavRPKDtjy1SNrUGdrgtq+iWkOaQbIQ=";
    };

    # doctor otherwise rewrites ~/.agents|.openclaw|.claude/skills/agent-reach on every run.
    postPatch = ''
      substituteInPlace agent_reach/cli.py --replace-fail \
        "    # Auto-install skill if not already present (fixes #154)" \
        "    return"
    '';

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postFixup = ''
      wrapProgram $out/bin/agent-reach --suffix PATH : ${lib.makeBinPath [ pkgs.ffmpeg-headless ]}
    '';

    build-system = [ py.hatchling ];

    dependencies = with py; [
      feedparser
      loguru
      python-dotenv
      pyyaml
      requests
      rich
      yt-dlp
    ] ++ lib.optional withCookies browser-cookie3;

    doCheck = false;

    meta = {
      description = "CLI giving AI agents read access to many internet platforms";
      homepage = "https://github.com/Panniantong/Agent-Reach";
      license = lib.licenses.mit;
      mainProgram = "agent-reach";
    };
  });

  # Session cookies come from the local browser at run time; nothing is stored here.
  bilibili-api-python = py.buildPythonPackage rec {
    pname = "bilibili-api-python";
    version = "17.4.2";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/8e/41/c12f4c52cecd6ca6c4bee49a8949ed3df3561e5dd12b891aba96dcdc4502/bilibili_api_python-${version}-py3-none-any.whl";
      hash = "sha256-keACsuC80+tQI541zrhJEztXT0B6kqBmNuHeEDG20J0=";
    };

    dependencies = with py; [
      beautifulsoup4
      colorama
      lxml
      pyyaml
      brotli
      qrcode
      apscheduler
      pillow
      yarl
      pycryptodomex
      qrcode-terminal
      pyjwt
    ];

    dontCheckRuntimeDeps = true;
    doCheck = false;
  };

  bili-cli = py.toPythonApplication (py.buildPythonPackage rec {
    pname = "bilibili-cli";
    version = "0.6.2";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/17/ec/3a91b3c75a066192ccfe01474bfc8705452244e70db2883d1b72fd43264b/bilibili_cli-${version}-py3-none-any.whl";
      hash = "sha256-GFtd8WJiQVyDCnQhbKnEp03w5jz1QlN0RPspWiNqn10=";
    };

    dependencies = with py; [
      aiohttp
      bilibili-api-python
      browser-cookie3
      click
      pyyaml
      qrcode
      rich
    ];

    dontCheckRuntimeDeps = true;
    doCheck = false;

    meta.mainProgram = "bili";
  });

  xclienttransaction = py.buildPythonPackage rec {
    pname = "xclienttransaction";
    version = "1.0.3";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/fa/a1/be735112ebe49916065e6f80017b93e92fc8880789c3f4f17380db7f531a/xclienttransaction-${version}-py3-none-any.whl";
      hash = "sha256-9z3SpLaFb5j6RfDNJsmg/cCyzroOebVSPN+KrH78Wf4=";
    };

    dependencies = [ py.beautifulsoup4 ];
    doCheck = false;
  };

  twitter-cli = py.toPythonApplication (py.buildPythonPackage {
    pname = "twitter-cli";
    version = "0.8.6";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "public-clis";
      repo = "twitter-cli";
      rev = "7c634e0d396b1e7af9f63315b414925fe4f29ae7";
      hash = "sha256-i6tkJS98LTMM1q7LGleblHeEg5mr4yaPSRe30lt2iTs=";
    };

    build-system = [ py.hatchling ];

    dependencies = with py; [
      beautifulsoup4
      browser-cookie3
      click
      curl-cffi
      pyyaml
      rich
      xclienttransaction
    ];

    doCheck = false;
    meta.mainProgram = "twitter";
  });

  rdt-cli = py.toPythonApplication (py.buildPythonPackage {
    pname = "rdt-cli";
    version = "0.4.2";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "public-clis";
      repo = "rdt-cli";
      rev = "5e4fb3720d5c174e976cd425ccc3b879d52cac66";
      hash = "sha256-LcilFSeMEqS5v2soDqAPPN5wCl4/U50jzdspOlq0s+I=";
    };

    build-system = [ py.hatchling ];

    dependencies = with py; [
      browser-cookie3
      click
      httpx
      pyyaml
      rich
    ];

    doCheck = false;
    meta.mainProgram = "rdt";
  });

  opencli = pkgs.buildNpmPackage rec {
    pname = "opencli";
    version = "2.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "jackwener";
      repo = "opencli";
      tag = "v${version}";
      hash = "sha256-8lPpOOBzRu7ssgC2rGzijm7s3H8P5uMkawCcp0KZyn4=";
    };

    npmDepsHash = "sha256-uFli8szZhhawB3x7a3EWAQK/hv2FAUrxxFU+f01oPhw=";

    # postinstall/prepare fetch adapters over the network; the build is offline.
    npmFlags = [ "--ignore-scripts" ];

    # --ignore-scripts also skips the prebuild-manifest hook, so run its steps by hand.
    npmBuildScript = "build-manifest";
    preBuild = ''
      npx tsc --build
      chmod +x dist/src/main.js
    '';

    meta = {
      description = "Turn websites into CLIs through the user's logged-in Chrome";
      homepage = "https://github.com/jackwener/opencli";
      license = lib.licenses.asl20;
      mainProgram = "opencli";
    };
  };

  # nixpkgs' patchright is a broken test stub; the real package is this prebuilt driver bundle.
  patchright = py.buildPythonPackage rec {
    pname = "patchright";
    version = "1.64.1";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/11/1a/2822f0f5a530d47161cc78fa35381023831e1068749378ecff3eb54a766d/patchright-${version}-py3-none-manylinux1_x86_64.whl";
      hash = "sha256-/19+L0a2yyYAjkAaLFLW/wnBwJuksk4sdbxQH2Kj8IQ=";
    };

    dependencies = with py; [ greenlet pyee ];

    postInstall = ''
      ln -sf ${lib.getExe pkgs.nodejs} $out/${py.python.sitePackages}/patchright/driver/node
    '';

    doCheck = false;
  };

  linkedin-mcp = py.toPythonApplication (py.buildPythonPackage rec {
    pname = "mcp-server-linkedin";
    version = "4.25.1";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "stickerdaniel";
      repo = "linkedin-mcp-server";
      tag = "v${version}";
      hash = "sha256-jmXQEsUDDnachGTulHkpapDXibYrYku4euNeIQlwEnU=";
    };

    build-system = [ py.setuptools ];

    dependencies = with py; [
      anyio
      cryptography
      fastmcp
      inquirer
      mcp
      packaging
      patchright
      pydantic-settings
      python-dotenv
      rich
      starlette
    ];

    dontCheckRuntimeDeps = true;
    doCheck = false;

    meta = {
      description = "MCP server giving AI assistants access to LinkedIn through the user's own browser session";
      homepage = "https://github.com/stickerdaniel/linkedin-mcp-server";
      license = lib.licenses.asl20;
      mainProgram = "mcp-server-linkedin";
    };
  });

  xiaohongshuBrowserVersion = "148.0.7778.215";

  # Fingerprint-patched Chromium the server insists on; it would download it at start otherwise.
  xiaohongshu-browser = pkgs.stdenv.mkDerivation {
    pname = "xiaohongshu-browser";
    version = xiaohongshuBrowserVersion;

    src = pkgs.fetchurl {
      url = "https://cdn.one-world.ai/browsers/${xiaohongshuBrowserVersion}/linux-x64.tar.xz";
      hash = "sha256-oKULoHvn2yK9dNrHnCOp/B87jL+KZHzC4ERlrhds23c=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
    ];

    runtimeDependencies = with pkgs; [ libGL vulkan-loader systemd ];

    # The Qt platform-theme shims are optional and load only when a Qt platform is detected.
    autoPatchelfIgnoreMissingDeps = [ "libQt5*" "libQt6*" ];

    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out
      runHook postInstall
    '';

    meta.platforms = [ "x86_64-linux" ];
  };

  xiaohongshu-mcp = pkgs.buildGoModule rec {
    pname = "xiaohongshu-mcp";
    version = "2.5.5";

    src = pkgs.fetchFromGitHub {
      owner = "xpzouying";
      repo = "xiaohongshu-mcp";
      tag = "v${version}";
      hash = "sha256-iqFfp5O7EOrS+WVm8g4ttEFDTTNQpFM61AHBsNOWNMU=";
    };

    vendorHash = "sha256-9Kqa81dX++OY28Ft9L5Ru0UTeiCnnxf9VUKfIhYdE5k=";

    postPatch = ''
      grep -qx '${xiaohongshuBrowserVersion}' browser/browser_version.txt
    '';

    ldflags = [ "-s" "-w" "-X main.version=v${version}" ];
    doCheck = false;

    meta = {
      description = "MCP server driving a headless browser for Xiaohongshu";
      homepage = "https://github.com/xpzouying/xiaohongshu-mcp";
      license = lib.licenses.mit;
      mainProgram = "xiaohongshu-mcp";
    };
  };

  chromePath = "${pkgs.google-chrome}/bin/google-chrome-stable";
  hasXiaohongshuBrowser = pkgs.stdenv.hostPlatform.system == "x86_64-linux";

  xiaoyuzhouPath = lib.makeBinPath (with pkgs; [
    bc
    coreutils
    curl
    ffmpeg-headless
    gawk
    gnugrep
    gnused
    perl
    (python3.withPackages (ps: [ ps.pyyaml ]))
  ]);
in
delib.module {
  name = "programs.agent-reach";

  options = with delib; moduleOptions {
    enable = boolOption false;
    browserChannels = boolOption false;
    opencliExtension = boolOption true;
  };

  nixos.ifEnabled = { cfg, ... }: lib.mkIf (cfg.browserChannels && cfg.opencliExtension) {
    programs.chromium = {
      enable = true;
      extensions = [ "ildkmabpimmkaediidaifkhjpohdnifk" ];
    };
  };

  home.ifEnabled = { cfg, myconfig, ... }:
    let
      agent-reach = mkAgentReach cfg.browserChannels;

      transcribe = pkgs.writeShellScript "transcribe.sh" ''
        export PATH=${xiaoyuzhouPath}:$PATH
        exec ${pkgs.bash}/bin/bash ${agent-reach}/${py.python.sitePackages}/agent_reach/scripts/transcribe_xiaoyuzhou.sh "$@"
      '';

      mcporterConfig = builtins.toJSON {
        mcpServers = {
          exa.baseUrl = "https://mcp.exa.ai/mcp";
        } // lib.optionalAttrs cfg.browserChannels ({
          linkedin-scraper = {
            command = lib.getExe linkedin-mcp;
            env.CHROME_PATH = chromePath;
          };
        } // lib.optionalAttrs hasXiaohongshuBrowser {
          xiaohongshu.baseUrl = "http://localhost:18060/mcp";
        });
      };
    in
    {
      assertions = [{
        assertion = myconfig.programs.claude-code.enable;
        message = "programs.agent-reach relies on gh and nodejs from programs.claude-code (claudeCodeTools).";
      }];

      home.packages = [
        agent-reach
        pkgs.mcporter
        pkgs.yt-dlp
      ] ++ lib.optionals cfg.browserChannels ([
        bili-cli
        twitter-cli
        rdt-cli
        opencli
        linkedin-mcp
      ] ++ lib.optional hasXiaohongshuBrowser xiaohongshu-mcp);

      xdg.configFile."mcporter/mcporter.json".text = mcporterConfig;

      xdg.configFile."yt-dlp/config".text = "--js-runtimes node\n";

      home.file.".agent-reach/tools/xiaoyuzhou/transcribe.sh".source = transcribe;

      xdg.cacheFile = lib.mkIf (cfg.browserChannels && hasXiaohongshuBrowser) {
        "xiaohongshu-mcp/browser/${xiaohongshuBrowserVersion}/chrome".source = "${xiaohongshu-browser}/chrome";
      };

      systemd.user.services.xiaohongshu-mcp = lib.mkIf (cfg.browserChannels && hasXiaohongshuBrowser) {
        Unit.Description = "Xiaohongshu MCP server";
        Service = {
          ExecStart = "${lib.getExe xiaohongshu-mcp} -port 127.0.0.1:18060";
          Environment = "COOKIES_PATH=%S/xiaohongshu-mcp/cookies.json";
          StateDirectory = "xiaohongshu-mcp";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
