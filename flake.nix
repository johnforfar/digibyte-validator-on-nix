# ./flake.nix

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

        # Main packages
        digibyted = pkgs.callPackage ./pkgs/digibyte {
          inherit (pkgs) clang llvmPackages;
          withGui = false;
        };

        dashboard = pkgs.callPackage ./pkgs/digibyte/dashboard {
          inherit digibyted;
        };

        # Container configuration
        containerSystem = pkgs.nixos ({
          imports = [ ./container.nix ];
          
          system.stateVersion = "24.05";
          
          # Container-specific config
          virtualisation.docker.enable = true;
          users.users.digibyte = {
            isSystemUser = true;
            group = "digibyte";
            home = "/var/lib/digibyte";
            createHome = true;
          };
          users.groups.digibyte = {};
        });

      in {
        # Packages
        packages = {
          inherit digibyted dashboard;
          container = containerSystem;
          default = digibyted;
        };

        # Apps
        apps.container = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "run-digibyte" ''
            #!/bin/sh
            exec ${pkgs.nixos-container}/bin/nixos-container run digibyte "$@"
          '';
          name = "run-digibyte";
        };
        
        apps.default = self.apps.${system}.container;

        # NixOS module
        nixosModules.default = import ./container.nix;
      });
}