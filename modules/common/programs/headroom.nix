{ delib, pkgs, lib, ... }:
let
  version = "0.44.0";

  wheelSrc = {
    "x86_64-linux" = {
      url = "https://files.pythonhosted.org/packages/8f/63/39c8f6bd317714bc6a68775be5da5e15bca9e91d5f95e259bc00e6de6f7f/headroom_ai-${version}-cp310-abi3-manylinux_2_28_x86_64.whl";
      hash = "sha256-O1x/0onn0ifc2biWYVVB6p09NziL2XsyV/yHacS373A=";
    };
    "aarch64-linux" = {
      url = "https://files.pythonhosted.org/packages/5e/d9/2ff01892de67c0824d024cdb0152e371bb8cd5ced8ed6c2a66ad5c5f13a4/headroom_ai-${version}-cp310-abi3-manylinux_2_28_aarch64.whl";
      hash = "sha256-WPLmrHNv6IL4PK4KO/+tfOV00SWH65mdZQG//QU6dc0=";
    };
    "aarch64-darwin" = {
      url = "https://files.pythonhosted.org/packages/42/b7/1ab4da6f7a091fd1a102b5194828f9a588b6b4f11b522f38b86b125770a3/headroom_ai-${version}-cp310-abi3-macosx_11_0_arm64.whl";
      hash = "sha256-mwhPTNmRivLQlwRQ/z6ZD//CmoIg3F4k+g8zpN0DWcw=";
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

    nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.autoPatchelfHook
    ];

    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ]);

    propagatedBuildInputs = with pkgs.python3Packages; [
      # base
      click
      filelock
      litellm
      opentelemetry-api
      pydantic
      pyyaml
      rich
      tiktoken
      tomlkit
      truststore

      # proxy
      fastapi
      h2
      httpx
      magika
      mcp
      onnxruntime
      openai
      orjson
      python-socks
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

  # toPythonApplication, not python3.withPackages: a withPackages env's bin/python
  # collides in home.packages with other python envs (school specialisation).
  headroom = pkgs.python3.pkgs.toPythonApplication headroom-pkg;

  proxyPort = 8787;
  proxyAddr = "127.0.0.1:${toString proxyPort}";

  statusHint =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "launchctl list com.headroom.proxy"
    else "systemctl --user status headroom-proxy";

  # Routes one `claude` invocation through the proxy; fails clearly when it is down.
  # 127.0.0.1 rather than localhost so the client never tries ::1 first.
  headroom-claude = pkgs.writeShellScriptBin "headroom-claude" ''
    if ! (exec 3<>/dev/tcp/127.0.0.1/${toString proxyPort}) 2>/dev/null; then
      echo "headroom-claude: proxy is not running on ${proxyAddr} (${statusHint})" >&2
      exit 1
    fi
    ANTHROPIC_BASE_URL="http://${proxyAddr}" ENABLE_TOOL_SEARCH=true exec claude "$@"
  '';

  shellAliases = {
    headroom-wrap = "headroom wrap claude";
  };
in
delib.module {
  name = "programs.headroom";

  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }: {
    home.packages = [ pkgs.ast-grep headroom headroom-claude ];

    programs = {
      fish.shellAbbrs = lib.mkIf (myconfig.constants.shell == "fish") shellAliases;
      zsh.shellAliases = lib.mkIf (myconfig.constants.shell == "zsh") shellAliases;
      bash.shellAliases = lib.mkIf (myconfig.constants.shell == "bash") shellAliases;
    };

    systemd.user.services.headroom-proxy = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit.Description = "Headroom AI context compression proxy";
      Service = {
        ExecStart = "${headroom}/bin/headroom proxy --port ${toString proxyPort}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    launchd.agents.headroom-proxy = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        Label = "com.headroom.proxy";
        ProgramArguments = [ "${headroom}/bin/headroom" "proxy" "--port" (toString proxyPort) ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
