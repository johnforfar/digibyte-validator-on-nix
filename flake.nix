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
          dashboard = pkgs.callPackage ./pkgs/digibyte/dashboard { };
          
          digibyte = pkgs.callPackage ./pkgs/digibyte {
            inherit (pkgs) clang llvmPackages;
            inherit (pkgs.qt6)
              qtbase
              qttools;
            inherit (pkgs)
              wrapQtAppsHook;
            withGui = !pkgs.stdenv.isDarwin;
          };
          
          digibyted = pkgs.callPackage ./pkgs/digibyte {
            inherit (pkgs) clang llvmPackages;
            withGui = false;
          };
          
          default = digibyted;
        };

        apps = rec {
          default = digibyted;
          
          digibyted = flake-utils.lib.mkApp {
            drv = self.packages.${system}.digibyted;
            name = "digibyted";
          };

          dashboard = flake-utils.lib.mkApp {
            drv = self.packages.${system}.dashboard;
            name = "digibyte-dashboard";
          };
        };
      }
    );
}