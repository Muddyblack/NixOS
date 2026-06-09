{pkgs, ...}: {
  home.file.".config/opencode/config.json".text = builtins.toJSON {
    "$schema" = "${pkgs.opencode}/share/opencode/config.json";
    model = "ollama/gemma4:e4b";
    provider = {
      ollama = {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama";
        options = {
          apiKey = "ollama";
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "gemma4:e4b" = {
            name = "Gemma 4 e4b";
          };
        };
      };
    };
  };
}
