{pkgs, ...}: let
  localModel = "gemma4:e4b";

  # OpenCode Go gateway (opencode.ai/zen/go). Serves the free stealth models,
  # including ox-alpha. Credentials come from `opencode auth login` (stored in
  # ~/.local/share/opencode/auth.json) or OPENCODE_API_KEY -- deliberately no
  # apiKey here, so an unset env var cannot shadow a stored credential.
  zenGoModels = {
    "ox-alpha-free" = {name = "OX Alpha (free)";};
  };
in {
  home.file.".config/opencode/config.json".text = builtins.toJSON {
    "$schema" = "${pkgs.opencode}/share/opencode/config.json";
    model = "ollama/${localModel}";
    provider = {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama";
        options = {
          apiKey = "ollama";
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          ${localModel} = {
            name = "Gemma 4 E4B";
          };
        };
      };
      opencode-go = {
        npm = "@ai-sdk/openai-compatible";
        name = "OpenCode Go";
        options = {
          baseURL = "https://opencode.ai/zen/go/v1";
        };
        models = zenGoModels;
      };
    };
  };
}
