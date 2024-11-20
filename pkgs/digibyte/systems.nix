# Update pkgs/digibyte/systems.nix:

{ lib }:

{
  x86_64-linux = {
    optFlags = [
      "-march=x86-64"
      "-mtune=generic"
      "-O2"
      "-pipe"
      "-fPIC"
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
      "-fPIC"
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
      "-fPIC"
      "-stdlib=libc++"
    ];
    extraConfig = [
      "--enable-hardening"
      "--with-daemon"
      "--with-gui=no"
    ];
  };

  aarch64-darwin = {
    optFlags = [
      "-march=armv8-a"
      "-O2"
      "-fPIC"
      "-stdlib=libc++"
    ];
    extraConfig = [
      "--enable-hardening"
      "--with-daemon"
      "--with-gui=no"
    ];
  };
}