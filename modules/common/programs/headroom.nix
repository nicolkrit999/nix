{ delib, pkgs, lib, ... }:
let
  version = "0.45.0";

  wheelSrc = {
    "x86_64-linux" = {
      url = "https://files.pythonhosted.org/packages/26/bc/aee4580f537985e7b9fa03b5ef2300f9e03828455c457e660911c25e2d6e/headroom_ai-${version}-cp310-abi3-manylinux_2_28_x86_64.whl";
      hash = "sha256-dcOG+52RJOqSWaYVZ/+kYSh1nyaVaRRZxufXUfnUwso=";
    };
    "aarch64-linux" = {
      url = "https://files.pythonhosted.org/packages/15/8b/8ee31bb6164670f91734b6580422bf2fb5e50517df9494c383afa6a3e459/headroom_ai-${version}-cp310-abi3-manylinux_2_28_aarch64.whl";
      hash = "sha256-Yb+IOVe82B0/DKCPLg0a9oKP1xDsfa0qB+/nmYt+sXs=";
    };
    "aarch64-darwin" = {
      url = "https://files.pythonhosted.org/packages/f5/38/1530981783c165d4350a5aee0556662ea6459d8edebbc64466acb26f7861/headroom_ai-${version}-cp310-abi3-macosx_11_0_arm64.whl";
      hash = "sha256-O3+e4mYDmrWosQxdpYaPm2QPH5SdNABdwmNivlJqUWU=";
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
