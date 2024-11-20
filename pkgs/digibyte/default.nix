# Create this file at pkgs/digibyte/default.nix:

{ lib
, stdenv
, fetchFromGitHub
, openssl
, boost
, libevent
, autoreconfHook
, db4
, pkg-config
, protobuf
, hexdump
, zeromq
, withGui ? true
, qtbase ? null
, qttools ? null
, wrapQtAppsHook ? null
, darwin ? null
}:

let
  systemConfig = (import ./systems.nix { inherit lib; }).${stdenv.hostPlatform.system} or {
    optFlags = [ "-O2" ];
    extraConfig = [ ];
  };
in
stdenv.mkDerivation rec {
  pname = "digibyte";
  version = "7.17.3";
  name = pname + toString (lib.optional (!withGui) "d") + "-" + version;

  src = fetchFromGitHub {
    owner = "digibyte-core";
    repo = pname;
    rev = "v${version}";
    sha256 = "zPwnC2qd28fA1saG4nysPlKU1nnXhfuSG3DpCY6T+kM=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    hexdump
  ] ++ lib.optionals withGui [
    wrapQtAppsHook
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Foundation
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.CoreServices
  ];

  buildInputs = [
    openssl
    boost
    libevent
    db4
    zeromq
  ] ++ lib.optionals withGui [
    qtbase
    qttools
    protobuf
  ];

  enableParallelBuilding = true;

  CFLAGS = toString systemConfig.optFlags;
  CXXFLAGS = toString systemConfig.optFlags;

  configureFlags = [
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ] ++ systemConfig.extraConfig;

  preConfigure = lib.optionalString stdenv.isDarwin ''
    export BOOST_INCLUDE_PATH="${boost.dev}/include"
    export BOOST_LIB_PATH="${boost.out}/lib"
    export EVENT_INCLUDE_PATH="${libevent.dev}/include"
    export EVENT_LIB_PATH="${libevent.out}/lib"
  '';

  meta = with lib; {
    description = "DigiByte (DGB) is a rapidly growing decentralized, global blockchain";
    homepage = "https://digibyte.io/";
    license = licenses.mit;
    maintainers = [ maintainers.mmahut ];
    platforms = platforms.unix;
    mainProgram = if withGui then "digibyte-qt" else "digibyted";
  };
}