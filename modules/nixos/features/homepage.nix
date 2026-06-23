{
  lib,
  config,
  ...
}: let
  mkService = name: attrs: {"${name}" = attrs;};
  mkBookmark = name: attrs: {"${name}" = [attrs];};
in {
  options.features.homepage.enable = lib.mkEnableOption "homepage dashboard";

  config = lib.mkIf config.features.homepage.enable {
    # Next.js standalone server binds 0.0.0.0 by default; force localhost-only.
    systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

    services.homepage-dashboard = {
      enable = true;
      listenPort = 8082;

      settings = {
        title = "homepage";
        description = "Local services, NixOS docs, dev tooling, and app references in one Homepage view.";
        favicon = "https://raw.githubusercontent.com/Muddyblack/NixOS/master/assets/nix_icon.svg";
        theme = "dark";
        color = "slate";
        iconStyle = "theme";
        headerStyle = "boxedWidgets";
        cardBlur = "xl";
        fullWidth = true;
        maxGroupColumns = 6;
        hideVersion = true;
        disableUpdateCheck = true;
        quicklaunch = {
          searchDescriptions = true;
          showSearchSuggestions = true;
          provider = "google";
        };
        background = {
          image = "https://raw.githubusercontent.com/Muddyblack/NixOS/master/assets/wallpapers/desktop.png";
          blur = "md";
          saturate = 75;
          brightness = 45;
          opacity = 40;
        };
        layout = {
          "Overview Services" = {
            tab = "Home";
            style = "row";
            columns = 4;
            icon = "mdi-view-dashboard-outline";
          };
          "AI Workspace" = {
            tab = "Home";
            style = "row";
            columns = 4;
            icon = "mdi-robot-outline";
          };
          "Web Apps" = {
            tab = "Apps";
            style = "row";
            columns = 4;
            icon = "mdi-application-outline";
          };
          "Installed Apps" = {
            tab = "Apps";
            style = "row";
            columns = 6;
            icon = "mdi-monitor-dashboard";
          };
          "CLI Reference" = {
            tab = "Dev";
            style = "row";
            columns = 6;
            icon = "mdi-console-line";
          };
          "Dev Stack" = {
            tab = "Dev";
            style = "row";
            columns = 6;
            icon = "mdi-hammer-wrench";
          };
          "NixOS Handbook" = {
            tab = "Docs";
            style = "row";
            columns = 6;
            icon = "mdi-book-open-page-variant-outline";
          };
          "Reference Shelf" = {
            tab = "Docs";
            style = "row";
            columns = 6;
            icon = "mdi-link-variant";
          };
        };
      };

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
            cputemp = true;
            uptime = true;
            units = "metric";
          };
        }
        {
          search = {
            provider = "google";
            target = "_blank";
            suggestionUrl = "https://www.google.com/complete/search?client=chrome&q=";
            showSearchSuggestions = true;
          };
        }
        {
          datetime = {
            text_size = "xl";
            format = {
              timeStyle = "short";
              dateStyle = "long";
              hourCycle = "h23";
            };
          };
        }
      ];

      services = [
        {
          "Overview Services" = [
            (mkService "Homepage" {
              icon = "homepage.svg";
              href = "http://localhost:8082";
              description = "Primary launcher and docs hub";
            })
            (mkService "Stirling PDF" {
              icon = "stirling-pdf.svg";
              href = "http://localhost:8080";
              description = "Local PDF tools";
            })
            (mkService "Firefly III" {
              icon = "firefly-iii.svg";
              href = "http://localhost:8083";
              description = "Personal finance and spending tracker";
            })
            (mkService "Netdata" {
              icon = "netdata.svg";
              href = "http://localhost:19999";
              description = "System monitoring";
            })
          ];
        }
        {
          "AI Workspace" = [
            (mkService "Ollama" {
              icon = "ollama.svg";
              href = "http://localhost:11434";
              description = "Local model runtime";
            })
            (mkService "Open WebUI" {
              icon = "open-webui.svg";
              href = "http://localhost:8765";
              description = "Local chat UI for Ollama";
            })
          ];
        }
        {
          "Web Apps" = [
            (mkService "GitHub" {
              icon = "mdi-github";
              href = "https://github.com/Muddyblack";
              description = "Code, issues, and PRs";
            })
            (mkService "NixOS Config" {
              icon = "mdi-file-code-outline";
              href = "https://github.com/Muddyblack/NixOS";
              description = "Current system repository";
            })
          ];
        }
      ];

      bookmarks = [
        {
          "Installed Apps" = [
            (mkBookmark "Zen Browser" {
              abbr = "ZN";
              href = "https://zen-browser.app";
              description = "Primary browser";
            })
            (mkBookmark "Obsidian" {
              abbr = "OB";
              href = "https://obsidian.md";
              description = "Notes and knowledge base";
            })
            (mkBookmark "Blender" {
              abbr = "BD";
              href = "https://www.blender.org";
              description = "3D work";
            })
            (mkBookmark "Inkscape" {
              abbr = "IK";
              href = "https://inkscape.org";
              description = "Vector editing";
            })
            (mkBookmark "OBS Studio" {
              abbr = "OBS";
              href = "https://obsproject.com";
              description = "Recording and streaming";
            })
            (mkBookmark "Localsend" {
              abbr = "LS";
              href = "https://localsend.org";
              description = "LAN file sharing";
            })
          ];
        }
        {
          "CLI Reference" = [
            (mkBookmark "ripgrep" {
              abbr = "RG";
              href = "https://github.com/BurntSushi/ripgrep";
              description = "Fast recursive search";
            })
            (mkBookmark "fd" {
              abbr = "FD";
              href = "https://github.com/sharkdp/fd";
              description = "Better find";
            })
            (mkBookmark "eza" {
              abbr = "EX";
              href = "https://github.com/eza-community/eza";
              description = "Better ls";
            })
            (mkBookmark "bat" {
              abbr = "BT";
              href = "https://github.com/sharkdp/bat";
              description = "Better cat";
            })
            (mkBookmark "btop" {
              abbr = "TP";
              href = "https://github.com/aristocratos/btop";
              description = "System monitor";
            })
            (mkBookmark "jq" {
              abbr = "JQ";
              href = "https://jqlang.github.io/jq/";
              description = "JSON processing";
            })
            (mkBookmark "xh" {
              abbr = "XH";
              href = "https://github.com/ducaale/xh";
              description = "Friendly HTTP client";
            })
            (mkBookmark "hyperfine" {
              abbr = "HF";
              href = "https://github.com/sharkdp/hyperfine";
              description = "Benchmark commands";
            })
          ];
        }
        {
          "Dev Stack" = [
            (mkBookmark "lazygit" {
              abbr = "LG";
              href = "https://github.com/jesseduffield/lazygit";
              description = "Git TUI";
            })
            (mkBookmark "GitHub CLI" {
              abbr = "GH";
              href = "https://cli.github.com/manual/";
              description = "PRs, repos, issues";
            })
            (mkBookmark "devenv" {
              abbr = "DV";
              href = "https://devenv.sh";
              description = "Declarative dev shells";
            })
            (mkBookmark "direnv" {
              abbr = "DE";
              href = "https://direnv.net";
              description = "Auto-load project env";
            })
            (mkBookmark "lazydocker" {
              abbr = "LD";
              href = "https://github.com/jesseduffield/lazydocker";
              description = "Container TUI";
            })
            (mkBookmark "k9s" {
              abbr = "K9";
              href = "https://k9scli.io";
              description = "Kubernetes TUI";
            })
            (mkBookmark "podman-compose" {
              abbr = "PC";
              href = "https://github.com/containers/podman-compose";
              description = "Compose on Podman";
            })
            (mkBookmark "Difftastic" {
              abbr = "DF";
              href = "https://difftastic.wilfred.me.uk";
              description = "Structural diffs";
            })
          ];
        }
        {
          "NixOS Handbook" = [
            (mkBookmark "NixOS Packages" {
              abbr = "NP";
              href = "https://search.nixos.org/packages";
              description = "Package search";
            })
            (mkBookmark "NixOS Options" {
              abbr = "NO";
              href = "https://search.nixos.org/options";
              description = "System option index";
            })
            (mkBookmark "Home Manager" {
              abbr = "HM";
              href = "https://home-manager-options.extranix.com";
              description = "User option index";
            })
            (mkBookmark "NixOS Wiki" {
              abbr = "NW";
              href = "https://wiki.nixos.org";
              description = "Community docs";
            })
            (mkBookmark "nix.dev" {
              abbr = "ND";
              href = "https://nix.dev";
              description = "Official guides";
            })
            (mkBookmark "Nixpkgs Manual" {
              abbr = "NM";
              href = "https://nixos.org/manual/nixpkgs/stable/";
              description = "Packaging and overlays";
            })
          ];
        }
        {
          "Reference Shelf" = [
            (mkBookmark "Devhints" {
              abbr = "DH";
              href = "https://devhints.io";
              description = "Cheatsheets";
            })
            (mkBookmark "ExplainShell" {
              abbr = "ES";
              href = "https://explainshell.com";
              description = "Break down shell commands";
            })
            (mkBookmark "Crontab Guru" {
              abbr = "CG";
              href = "https://crontab.guru";
              description = "Cron helper";
            })
            (mkBookmark "Regex101" {
              abbr = "RX";
              href = "https://regex101.com";
              description = "Regex tester";
            })
            (mkBookmark "Docker Docs" {
              abbr = "DD";
              href = "https://docs.docker.com";
              description = "Containers reference";
            })
            (mkBookmark "Kubernetes Docs" {
              abbr = "K8";
              href = "https://kubernetes.io/docs/";
              description = "Cluster reference";
            })
            (mkBookmark "HTMX Reference" {
              abbr = "HX";
              href = "https://htmx.org/reference/";
              description = "Attribute reference";
            })
            (mkBookmark "Linux Man Pages" {
              abbr = "MAN";
              href = "https://www.man7.org/linux/man-pages/";
              description = "System man pages";
            })
          ];
        }
      ];

      customCSS = ''
        :root {
          --font-sans: "SF Pro Display", "Inter", "Segoe UI Variable", system-ui, sans-serif;
          --font-mono: "JetBrains Mono", "SFMono-Regular", monospace;
          --acc:  168, 85,  247;
          --acc2: 56,  189, 248;
          --acc3: 244, 114, 182;
        }

        * { box-sizing: border-box; }

        body {
          font-family: var(--font-sans) !important;
          background-color: #04060f !important;
          -webkit-font-smoothing: antialiased !important;
        }

        body::before {
          content: "";
          position: fixed;
          inset: 0;
          z-index: -1;
          pointer-events: none;
          background:
            radial-gradient(ellipse 70% 55% at 12% 0%,   rgba(56,  189, 248, 0.10), transparent),
            radial-gradient(ellipse 60% 50% at 88% 5%,   rgba(168, 85,  247, 0.15), transparent),
            radial-gradient(ellipse 50% 45% at 50% 100%, rgba(244, 114, 182, 0.10), transparent),
            linear-gradient(180deg, #04060f 0%, #060819 100%);
        }

        #information-widgets {
          margin: 20px auto 8px !important;
          max-width: min(1440px, calc(100vw - 40px)) !important;
          padding: 8px 14px !important;
          border: 1px solid rgba(255,255,255,0.07) !important;
          border-radius: 22px !important;
          background: rgba(10, 13, 26, 0.75) !important;
          backdrop-filter: blur(36px) saturate(170%) !important;
          -webkit-backdrop-filter: blur(36px) saturate(170%) !important;
          box-shadow:
            0 0 0 1px rgba(255,255,255,0.04) inset,
            0 1px 0   rgba(255,255,255,0.07) inset,
            0 28px 72px rgba(4, 6, 15, 0.60) !important;
        }

        .information-widget,
        .information-widget-datetime,
        .information-widget-search,
        .information-widget-resources {
          border-radius: 14px !important;
        }

        #search-container,
        #search-box,
        #searchbox,
        #searchbar,
        form[action="/api/search"] {
          background: transparent !important;
        }

        #searchbox input,
        input[type="text"][placeholder],
        input[type="search"] {
          border-radius: 12px !important;
          border: 1px solid rgba(255,255,255,0.09) !important;
          background: rgba(8, 11, 24, 0.70) !important;
          backdrop-filter: blur(16px) !important;
          font-family: var(--font-sans) !important;
          box-shadow:
            inset 0 1px 0 rgba(255,255,255,0.04),
            0 2px 8px rgba(4,6,15,0.35) !important;
          transition: border-color 0.2s ease, box-shadow 0.2s ease !important;
        }

        #searchbox input:focus,
        input[type="search"]:focus {
          border-color: rgba(var(--acc), 0.50) !important;
          box-shadow:
            inset 0 1px 0 rgba(255,255,255,0.05),
            0 0 0 3px rgba(var(--acc), 0.13),
            0 4px 16px rgba(4,6,15,0.40) !important;
          outline: none !important;
        }

        .service-card,
        .bookmark,
        .card {
          position: relative !important;
          border-radius: 20px !important;
          border: 1px solid rgba(255,255,255,0.07) !important;
          background: rgba(14, 18, 36, 0.80) !important;
          backdrop-filter: blur(24px) saturate(155%) !important;
          -webkit-backdrop-filter: blur(24px) saturate(155%) !important;
          overflow: hidden !important;
          box-shadow:
            0 0 0 1px rgba(255,255,255,0.03) inset,
            0 1px 0   rgba(255,255,255,0.08) inset,
            0 16px 44px rgba(4, 6, 15, 0.45) !important;
          transition:
            transform 0.24s cubic-bezier(0.34,1.2,0.64,1),
            border-color 0.2s ease,
            box-shadow 0.2s ease !important;
        }

        .service-card::before,
        .bookmark::before {
          content: "";
          position: absolute;
          inset: 0;
          border-radius: 20px;
          background: linear-gradient(135deg, rgba(255,255,255,0.04) 0%, transparent 55%);
          pointer-events: none;
          z-index: 0;
        }

        .service-card:hover,
        .bookmark:hover,
        .card:hover {
          transform: translateY(-3px) scale(1.012) !important;
          border-color: rgba(var(--acc), 0.38) !important;
          box-shadow:
            0 0 0 1px rgba(var(--acc), 0.10) inset,
            0 1px 0   rgba(255,255,255,0.10) inset,
            0 0 30px rgba(var(--acc), 0.13),
            0 28px 60px rgba(4, 6, 15, 0.58) !important;
        }

        .service-card a,
        .bookmark a,
        .service-name,
        .bookmark-text,
        .service-description,
        .bookmark-description {
          font-family: var(--font-sans) !important;
          position: relative;
          z-index: 1;
        }

        .service-name {
          font-weight: 600 !important;
          font-size: 14px !important;
          letter-spacing: -0.01em !important;
        }

        .service-description,
        .bookmark-description {
          font-size: 12px !important;
          opacity: 0.62 !important;
        }

        .bookmark-abbr,
        .abbr {
          font-family: var(--font-mono) !important;
          font-size: 11px !important;
          font-weight: 700 !important;
          letter-spacing: 0.04em !important;
          background: rgba(var(--acc), 0.14) !important;
          border: 1px solid rgba(var(--acc), 0.30) !important;
          color: rgba(var(--acc), 1) !important;
          border-radius: 8px !important;
          padding: 2px 8px !important;
          min-width: 34px !important;
          text-align: center !important;
        }

        .service-icon,
        .bookmark-icon {
          filter: drop-shadow(0 4px 12px rgba(4,6,15,0.55));
          transition: filter 0.2s ease;
        }

        .service-card:hover .service-icon,
        .bookmark:hover .bookmark-icon {
          filter: drop-shadow(0 6px 20px rgba(var(--acc), 0.35));
        }

        .group-title,
        .category-title {
          font-size: 10px !important;
          font-weight: 700 !important;
          letter-spacing: 0.18em !important;
          text-transform: uppercase !important;
          color: rgba(var(--acc2), 0.70) !important;
          margin-bottom: 10px !important;
        }

        [role="tablist"],
        .tabs {
          margin: 0 auto 10px !important;
          max-width: min(1440px, calc(100vw - 40px)) !important;
          gap: 6px !important;
        }

        [role="tab"],
        .tab {
          border-radius: 999px !important;
          font-size: 13px !important;
          font-weight: 500 !important;
          padding: 7px 22px !important;
          border: 1px solid transparent !important;
          transition: background 0.2s ease, color 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease !important;
        }

        [role="tab"]:hover,
        .tab:hover {
          background: rgba(255,255,255,0.06) !important;
        }

        [role="tab"][aria-selected="true"],
        .tab.active {
          background: rgba(var(--acc), 0.16) !important;
          border-color: rgba(var(--acc), 0.32) !important;
          box-shadow:
            inset 0 1px 0 rgba(255,255,255,0.06),
            0 2px 14px rgba(var(--acc), 0.20) !important;
        }

        ::-webkit-scrollbar { width: 5px; height: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb {
          background: rgba(var(--acc), 0.28);
          border-radius: 999px;
        }
        ::-webkit-scrollbar-thumb:hover { background: rgba(var(--acc), 0.50); }

        @media (max-width: 900px) {
          #information-widgets {
            max-width: calc(100vw - 20px) !important;
            margin-top: 12px !important;
            border-radius: 16px !important;
          }
          [role="tablist"],
          .tabs {
            max-width: calc(100vw - 20px) !important;
          }
        }
      '';
    };
  };
}
