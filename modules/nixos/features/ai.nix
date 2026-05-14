{
  lib,
  config,
  ...
}: {
  options.features.ai.enable = lib.mkEnableOption "AI services (Ollama)";

  config = lib.mkIf config.features.ai.enable {
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
    };
  };
}
