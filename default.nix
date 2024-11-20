let
  nixpkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") {
    config = {
      allowUnfree = true;
    };
  };
in
nixpkgs.callPackage ./pkgs/digibyte {
  inherit (nixpkgs) qtbase qttools wrapQtAppsHook;
  withGui = true;
}