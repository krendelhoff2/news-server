{
  description = "The news-server flake";

  inputs = {
    haskell-nix.url = "github:input-output-hk/haskell.nix";
    nixpkgs.follows = "haskell-nix/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, haskell-nix, ... }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ] (system:
    let
      pkgs = import nixpkgs {
        inherit system; inherit (haskell-nix) config;
        overlays = [
          haskell-nix.overlay
          (final: prev: {

            news-server = final.haskell-nix.hix.project {
              src = pkgs.haskell-nix.haskellLib.cleanGit {
                name = "news-server";
                src = ./.;
              };
              projectFileName = "stack.yaml";
              evalSystem = "x86_64-linux";
            };

            components = (final.news-server.flake {}).packages;
          })
        ];
      };

      flake = pkgs.news-server.flake {};

    in nixpkgs.lib.recursiveUpdate flake {

      legacyPackages = pkgs;

      packages.default = flake.packages."server:exe:server";

      devShells.default = flake.devShell;
    });

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
