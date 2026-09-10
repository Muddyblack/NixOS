{
  config,
  lib,
  pkgs,
  ...
}: let
  catalogue = {
    inherit
      (pkgs.unstable)
      aider-chat
      amp-cli
      claude-code
      codex
      crush
      cursor-cli
      github-copilot-cli
      goose-cli
      grok-build
      kiro-cli
      pi-coding-agent
      qwen-code
      ;
    inherit
      (pkgs)
      auggie
      cline
      droid
      google-antigravity-cli
      junie
      kimi-code
      mistral-vibe
      muse
      opencode
      openhands-cli
      ;
  };
in {
  options.ai.agents = lib.mkOption {
    type = lib.types.listOf (lib.types.enum (lib.attrNames catalogue));
    default = [];
    description = "AI coding agent CLIs to install, by catalogue name";
  };

  config.home.packages = map (name: catalogue.${name}) config.ai.agents;
}
