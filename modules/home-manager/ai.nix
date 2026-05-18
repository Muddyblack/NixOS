{...}: {
  home.file.".config/opencode/config.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "ollama/gemma4:e4b";
    providers = {
      ollama = {
        name = "Ollama";
        apiUrl = "http://localhost:11434/v1";
      };
    };
    context_length = 32768;
  };
}
