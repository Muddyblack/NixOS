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

    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Without the follows, impermanence dragged in its own nixpkgs (locked
    # ~7 months behind ours) *and* a second home-manager, both evaluated for
    # nothing. Its module only needs lib.
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # No inputs.nixpkgs.follows here: nix-flatpak is a module-only flake and
    # declares no nixpkgs input, so a follows on it is what triggers the
    # "override for a non-existent input" warning on every evaluation.
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Only the home-manager module is used from here; the packages come from
    # nixpkgs-unstable (see the overlay below). quickshell is nulled out because
    # the flake would otherwise build it from git master - hours of clang, with
    # no public cache carrying that derivation.
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "";
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

    plasma-audio-visualizer = {
      url = "github:Muddyblack/kde-audio-visualizer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitpulse = {
      url = "github:Muddyblack/kde-gitpulse";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  # Service ports reference:
  #   Ollama       → http://localhost:11434
  #   Open WebUI   → http://localhost:8765
  #   Homepage     → http://localhost:8082
  #   Firefly III  → http://localhost:8083
  #   Stirling-PDF → http://localhost:8080
  #   Paperless    → http://localhost:28981

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
                # caelestia-shell/-cli exist only in unstable, and only there are
                # they - plus their quickshell dependency - prebuilt on cache.nixos.org.
                # Building caelestia-shell.homeManagerModules default instead compiles
                # quickshell from git on every input bump: hours of clang, since no
                # public cache carries those derivations.
                inherit
                  (unstablePkgs)
                  caelestia-cli
                  caelestia-shell
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
                # The default FHS/bwrap variant nests Electron's own Chromium
                # sandbox inside bwrap's "no new privileges" environment,
                # which crash-loops the GPU process (coredumps + forced
                # software-WebGL rendering, burning CPU). The flake ships a
                # no-fhs variant using autoPatchelfHook instead of bwrap,
                # avoiding the nested-sandbox conflict entirely.
                google-antigravity-ide = inputs.antigravity-nix.packages.${prev.stdenv.hostPlatform.system}.google-antigravity-ide-no-fhs;
              })
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupCommand = "${pkgs.coreutils}/bin/rm -rf";
              users.${username} = import ./modules/home-manager/home.nix;
              extraSpecialArgs = {inherit inputs username;};

              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                inputs.cosmic-manager.homeManagerModules.default
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
