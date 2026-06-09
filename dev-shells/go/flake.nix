{
  description = "A Nix-flake-based Go development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs = {...} @ inputs: let
    goVersion = 25; # Change this to update the whole stack

    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [inputs.self.overlays.default];
            };
          }
      );
  in {
    overlays.default = final: _prev: {
      go = final."go_1_${toString goVersion}";
    };

    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            # go (version is specified by overlay)
            go

            # Some generator dependencies still build through cgo.
            gcc

            (python3.withPackages (ps:
              with ps; [
                ruamel-yaml
              ]))

            # goimports, godoc, etc.
            gotools

            # Project fmt target dependencies.
            gofumpt
            gci
            golines

            # https://github.com/golangci/golangci-lint
            golangci-lint
          ];

          shellHook = ''
            export GOBIN="$PWD/.direnv/go/bin"
            export PATH="$GOBIN:$PATH"
            mkdir -p "$GOBIN"
            mkdir -p "$PWD/venv/bin"
            ln -sfn "$(command -v python3)" "$PWD/venv/bin/python"
          '';
        };
      }
    );
  };
}
