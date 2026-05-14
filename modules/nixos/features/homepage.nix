{
  lib,
  config,
  ...
}: {
  options.features.homepage.enable = lib.mkEnableOption "homepage dashboard";

  config = lib.mkIf config.features.homepage.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = 8082;
      settings = {
        title = "NixOS Dashboard";
        favicon = "https://nixos.org/favicon.png";
        theme = "dark";
        color = "slate";
        headerStyle = "clean";
        layout = {
          System = {
            style = "row";
            columns = 4;
          };
          Automation = {
            style = "row";
            columns = 2;
          };
          Development = {
            style = "row";
            columns = 3;
          };
        };
      };
      services = [
        {
          "System" = [
            {
              "Netdata" = {
                icon = "netdata.svg";
                href = "http://localhost:19999";
                description = "System monitoring";
                widget = {
                  type = "netdata";
                  url = "http://localhost:19999";
                };
              };
            }
            {
              "Ollama" = {
                icon = "ollama.svg";
                href = "http://localhost:11434";
                description = "Local AI models";
              };
            }
            {
              "Open WebUI" = {
                icon = "open-webui.svg";
                href = "http://localhost:8080";
                description = "LLM chat interface";
              };
            }
          ];
        }
        {
          "Development" = [
            {
              "Nix Store" = {
                icon = "nixos.svg";
                description = "Package management";
                widget = {
                  type = "customapi";
                  url = "http://localhost:19999/api/v1/info";
                  mappings = [
                    {
                      field = "os_name";
                      label = "OS";
                    }
                  ];
                };
              };
            }
          ];
        }
      ];
      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
        {
          search = {
            provider = "google";
            target = "_blank";
          };
        }
      ];
      bookmarks = [
        {
          "Quick Links" = [
            {
              "NixOS Search" = [
                {
                  abbr = "NX";
                  href = "https://search.nixos.org/packages";
                }
              ];
            }
            {
              "NixOS Wiki" = [
                {
                  abbr = "NW";
                  href = "https://wiki.nixos.org";
                }
              ];
            }
            {
              "Home Manager Options" = [
                {
                  abbr = "HM";
                  href = "https://home-manager-options.extranix.com";
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
