{pkgs, ...}: let
  localModel = "gemma4:e4b";
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
    };
  };
}
