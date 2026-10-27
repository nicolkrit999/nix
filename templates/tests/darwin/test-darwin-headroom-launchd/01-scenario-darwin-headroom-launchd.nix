let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host-darwin.nix flake;
  inherit (fx) hmOf;

  host = fx.mkDarwin {
    paths = [ (fx.src + "/modules/common/programs/headroom.nix") ];
    modules = [{ myconfig.programs.headroom.enable = true; }];
  };
  hm = hmOf host.config;

  agent = hm.launchd.agents.headroom-proxy;
  args = agent.config.ProgramArguments;
  pkgByName = cfg: pred: lib.findFirst pred null (hmOf cfg).home.packages;
  wrapper = pkgByName host.config (p: (p.name or "") == "headroom-claude");
  proxyPkg = pkgByName host.config (p: lib.hasPrefix "headroom-ai-" (p.name or ""));

  portArg = lib.last args;
  portFromWrapper = builtins.match ".*/dev/tcp/127\\.0\\.0\\.1/([0-9]+).*" wrapper.text;

  withoutHeadroom = fx.mkDarwin {
    paths = [ (fx.src + "/modules/common/programs/headroom.nix") ];
  };

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkEq = name: actual: expected:
    check name (actual == expected) "expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
in
{
  check-agent-declared =
    check "home-manager launchd.agents.headroom-proxy exists and is enabled"
      (hm.launchd.agents ? headroom-proxy && agent.enable) "agent missing or disabled";
  check-agent-label = checkEq "launchd Label" agent.config.Label "com.headroom.proxy";
  check-agent-keepalive =
    check "agent starts at login and is restarted (RunAtLoad + KeepAlive)"
      (agent.config.RunAtLoad == true && agent.config.KeepAlive == true)
      "RunAtLoad=${builtins.toJSON agent.config.RunAtLoad} KeepAlive=${builtins.toJSON agent.config.KeepAlive}";
  check-agent-args-shape =
    check "ProgramArguments = [<store>/bin/headroom proxy --port <n>]"
      (builtins.length args == 4 && lib.hasSuffix "/bin/headroom" (builtins.elemAt args 0)
        && builtins.elemAt args 1 == "proxy" && builtins.elemAt args 2 == "--port")
      "args=${builtins.toJSON args}";
  check-agent-port = checkEq "proxy port" portArg "8787";
  check-wrapper-targets-loopback =
    check "headroom-claude probes 127.0.0.1 (not localhost / ::1) on the agent's port and exports the same base URL"
      (wrapper != null && portFromWrapper == [ portArg ] && lib.hasInfix "ANTHROPIC_BASE_URL=\"http://127.0.0.1:${portArg}\"" wrapper.text)
      "wrapper port=${builtins.toJSON portFromWrapper} agent port=${portArg}";
  check-wrapper-darwin-hint =
    check "headroom-claude points at launchctl (not systemctl) when the proxy is down"
      (lib.hasInfix "launchctl list com.headroom.proxy" wrapper.text && !(lib.hasInfix "systemctl" wrapper.text))
      "status hint is not the darwin one";
  check-no-systemd-unit =
    check "no systemd headroom-proxy unit on the darwin host"
      (!(hm.systemd.user.services ? headroom-proxy)) "systemd unit leaked into the darwin config";
  check-wheel-is-darwin =
    check "the headroom-ai package src is the macosx arm64 wheel"
      (proxyPkg != null && lib.hasInfix "macosx" proxyPkg.src.name && lib.hasInfix "arm64" proxyPkg.src.name)
      "src=${if proxyPkg == null then "no package" else proxyPkg.src.name}";
  check-control-disabled =
    check "control: with programs.headroom left off the agent and wrapper vanish"
      (!((hmOf withoutHeadroom.config).launchd.agents ? headroom-proxy)
        && pkgByName withoutHeadroom.config (p: (p.name or "") == "headroom-claude") == null)
      "agent or wrapper survived disabling the module";
  check-control-port-regex =
    check "control: the port regex does not match a non-loopback probe"
      (builtins.match ".*/dev/tcp/127\\.0\\.0\\.1/([0-9]+).*" "exec 3<>/dev/tcp/localhost/8787" == null)
      "regex matches localhost";
}
