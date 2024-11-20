{
  description = "Multi-architecture DigiByte validator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
        };
      in
      {
        packages = rec {
          digibyte = pkgs.callPackage ./pkgs/digibyte {
            inherit (pkgs) qtbase qttools wrapQtAppsHook;
            withGui = true;
          };
          digibyted = pkgs.callPackage ./pkgs/digibyte {
            withGui = false;
          };
          default = digibyte;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            boost
            openssl
            libevent
            db4
            zeromq
          ];
        };
      }
    );
}