{
  description = "Custom Nix repository for DigiByte";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        packages = {
          digibyte = pkgs.callPackage ./pkgs/digibyte {
            withGui = true;
          };
          digibyted = pkgs.callPackage ./pkgs/digibyte {
            withGui = false;
          };
          default = self.packages.${system}.digibyte;
        };
      }
    );
}