{ delib, pkgs, lib, ... }:
let
  version = "0.27.0";

  wheelSrc = {
    "x86_64-linux" = {
      url = "https://files.pythonhosted.org/packages/8f/70/2e287f4f4bc8306c8c51bb40e753cfdfa05c568d026be633c78d9f4f2995/headroom_ai-${version}-cp310-abi3-manylinux_2_28_x86_64.whl";
      hash = "sha256-ZA5npBdDJlN2WCqSaRoZKowkSO8LIWeg4UoqRYrb4t0=";
    };
    "aarch64-linux" = {
      url = "https://files.pythonhosted.org/packages/0e/b4/e5e32e7042f7bb7bdb3aaec1dd9b31926e38612f61b5a3d5f31253f2b646/headroom_ai-${version}-cp310-abi3-manylinux_2_28_aarch64.whl";
      hash = "sha256-+PoVAGHbJRPoWE0uS1CvkwExvP4wEIDyl0ZLNRoD9Xc=";
    };
    "aarch64-darwin" = {
      url = "https://files.pythonhosted.org/packages/10/95/928bfb645df23025fb375de19c7d57ec21a0991712236d7748ce456139e3/headroom_ai-${version}-cp310-abi3-macosx_11_0_arm64.whl";
      hash = "sha256-ALVLcFM8hB9HAv/68hXv+Euv7XYSwHpW1nXvih/6tUM=";
    };
  };

  currentSystem = pkgs.stdenv.hostPlatform.system;

  headroom-pkg = pkgs.python3.pkgs.buildPythonPackage {
    pname = "headroom-ai";
    inherit version;
    format = "wheel";

    src = pkgs.fetchurl {
      url = wheelSrc.${currentSystem}.url;
      hash = wheelSrc.${currentSystem}.hash;
    };

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];

    buildInputs = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ]);

    propagatedBuildInputs = with pkgs.python3Packages; [
      # base
      click
      litellm
      opentelemetry-api
      pydantic
      rich
      tiktoken

      # proxy
      fastapi
      h2
      httpx
      magika
      mcp
      onnxruntime
      openai
      sqlite-vec
      transformers
      uvicorn
      watchdog
      websockets
      zstandard
    ];

    dontCheckRuntimeDeps = true;
    doCheck = false;

    meta = {
      description = "AI context compression CLI - reduces token usage 60-95% for LLM agents";
      homepage = "https://github.com/chopratejas/headroom";
      license = lib.licenses.asl20;
      platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      mainProgram = "headroom";
    };
  };

  headroom = pkgs.python3.withPackages (_: [ headroom-pkg ]);

  shellAliases = {
    headroom-wrap = "headroom wrap claude";
    headroom-claude = "ANTHROPIC_BASE_URL=http://localhost:8787 ENABLE_TOOL_SEARCH=true claude";
  };
in
delib.module {
  name = "programs.headroom";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }: {
    home.packages = [ headroom pkgs.ast-grep ];

    programs.fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") shellAliases;
    programs.zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") shellAliases;
    programs.bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") shellAliases;

    systemd.user.services.headroom-proxy = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Headroom AI context compression proxy";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${headroom}/bin/headroom proxy --port 8787";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    launchd.agents.headroom-proxy = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        Label = "com.headroom.proxy";
        ProgramArguments = [ "${headroom}/bin/headroom" "proxy" "--port" "8787" ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
