# pkgs/univalue/default.nix

{ lib
, stdenv
, fetchFromGitHub
, autoreconfHook
, pkg-config
}:

stdenv.mkDerivation rec {
  pname = "univalue";
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "bitcoin-core";
    repo = "univalue";
    rev = "v${version}";
    sha256 = "1ww45wjbbw441qv1rlqqs5i1cr28cxkp4lj7kqjkgjp0jf62swvx";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  configureFlags = [
    "--enable-static"
    "--disable-shared"
  ];

  meta = with lib; {
    description = "Universal Value object and JSON library";
    homepage = "https://github.com/bitcoin-core/univalue";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}

# Update flake.nix:

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

        univalue = pkgs.callPackage ./pkgs/univalue {};
      in
      {
        packages = rec {
          inherit univalue;
          
          digibyte = pkgs.callPackage ./pkgs/digibyte {
            inherit univalue;
            inherit (pkgs.qt6)
              qtbase
              qttools;
            inherit (pkgs)
              wrapQtAppsHook;
            withGui = !pkgs.stdenv.isDarwin;
          };
          
          digibyted = pkgs.callPackage ./pkgs/digibyte {
            inherit univalue;
            withGui = false;
          };
          
          default = digibyted;
        };
      }
    );
}