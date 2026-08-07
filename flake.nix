{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    impermanence.url = "github:nix-community/impermanence";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Own widgets, tracking their default branch rather than a tag: a tag-pinned
    # input never moves, so `nix flake update` is a no-op on it and the
    # Nixdatifier widget (which ls-remotes each root input's ref) would report
    # it as "unchanged" forever.
    ai-usage = {
      url = "github:Muddyblack/kde-ai-usage";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glassy-system-monitor = {
      url = "github:Muddyblack/kde-glassy-system-monitor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixdatifier = {
      url = "github:Muddyblack/kde-nixdatifier";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tagesschau-widget = {
      url = "github:Muddyblack/kde-tagesschau-rss-widget";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  # Service ports reference:
  #   Netdata      → http://localhost:19999
  #   Ollama       → http://localhost:11434
  #   Open WebUI   → http://localhost:8765
  #   Homepage     → http://localhost:8082
  #   Firefly III  → http://localhost:8083

  outputs = {
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    disko,
    plasma-manager,
    impermanence,
    ...
  } @ inputs: let
    username = "muddyblack";

    unstablePkgs = import nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    # Desktop host: full home-manager + plasma-manager
    mkHost = hostModule:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username;};
        modules = [
          {nixpkgs.hostPlatform = "x86_64-linux";}
          disko.nixosModules.disko
          impermanence.nixosModules.impermanence
          inputs.nix-flatpak.nixosModules.nix-flatpak
          hostModule
          home-manager.nixosModules.home-manager
          ({pkgs, ...}: {
            nixpkgs.overlays = [
              (import ./pkgs inputs)
              inputs.nur.overlays.default
              inputs.nix-cachyos-kernel.overlays.pinned
              (_final: prev: {
                inherit
                  (unstablePkgs)
                  claude-code
                  codex
                  grok-build
                  mistral-vibe
                  tailscale
                  typst
                  typstyle
                  tinymist
                  kiro
                  zed-editor
                  vscode
                  ;
                google-antigravity = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.google-antigravity;
                google-antigravity-cli = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.google-antigravity-cli;
                google-antigravity-ide = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.google-antigravity-ide;
              })
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupCommand = "${pkgs.coreutils}/bin/rm -f";
              users.${username} = import ./modules/home-manager/home.nix;
              extraSpecialArgs = {inherit inputs username;};

              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                inputs.caelestia-shell.homeManagerModules.default
              ];
            };
          })
        ];
      };
  in {
    templates = import ./dev-shells/default.nix;

    nixosConfigurations = {
      muddyblack = mkHost ./hosts/muddyblack/configuration.nix;
      muddyblack-lite = mkHost ./hosts/muddyblack-lite/configuration.nix;
    };

    devShells = let
      systems = ["x86_64-linux" "aarch64-linux"];
      forEachSystem = nixpkgs.lib.genAttrs systems;
    in
      forEachSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (import ./pkgs inputs)
            (_final: _prev: {
              inherit (unstablePkgs) typst typstyle tinymist;
            })
          ];
        };
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nix
            git
            just
            sops
            age
            alejandra
            deadnix
          ];
          shellHook = ''
            echo "❄️ NixOS Config Dev Shell Loaded"
          '';
        };
      });
  };
}
