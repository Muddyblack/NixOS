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
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
      };
    };

    services.open-webui = {
      enable = true;
      host = "127.0.0.1";
      port = 8765;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
        WEBUI_AUTH = "False";
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
      };
    };

    systemd.services.open-webui.wantedBy = lib.mkForce [];
  };
}
