{
  description = "A Nix-flake-based Bun and Node.js development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  outputs = {...} @ inputs: let
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
              config.allowUnfree = true;
            };
          }
      );
  in {
    devShells = forEachSupportedSystem (
      {pkgs}: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            bun
            node2nix
            nodejs
            pnpm
            yarn
            # Native dependencies for 'canvas'
            pkg-config
            cairo
            pango
            libpng
            libjpeg
            giflib
            librsvg
            pixman
            python3
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.cairo
              pkgs.pango
              pkgs.libpng
              pkgs.libjpeg
              pkgs.giflib
              pkgs.librsvg
            ]}:$LD_LIBRARY_PATH"
          '';
        };
      }
    );
  };
}
