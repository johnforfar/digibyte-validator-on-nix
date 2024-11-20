# Create this file at pkgs/digibyte/systems.nix:

{ lib }:

{
  # System-specific configurations
  x86_64-linux = {
    optFlags = [
      "-march=x86-64"
      "-mtune=generic"
      "-O2"
      "-pipe"
    ];
    extraConfig = [
      "--enable-hardening"
    ];
  };

  aarch64-linux = {
    optFlags = [
      "-march=armv8-a"
      "-O2"
      "-pipe"
    ];
    extraConfig = [
      "--enable-hardening"
    ];
  };

  x86_64-darwin = {
    optFlags = [
      "-march=x86-64"
      "-mtune=generic"
      "-O2"
    ];
    extraConfig = [
      "--enable-hardening"
      "--with-daemon"
    ];
  };

  aarch64-darwin = {
    optFlags = [
      "-march=armv8-a"
      "-O2"
    ];
    extraConfig = [
      "--enable-hardening"
      "--with-daemon"
    ];
  };
}