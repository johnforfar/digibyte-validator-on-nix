# pkgs/digibyte/default.nix:

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
, which
, autoconf
, automake
, libtool
, python3
, binutils-unwrapped
, withGui ? false
, qtbase ? null
, qttools ? null
, wrapQtAppsHook ? null
, darwin ? null
}:

let
  darwinBuildInputs = with darwin.apple_sdk; [
    frameworks.Foundation
    frameworks.AppKit
    frameworks.CoreServices
    frameworks.DiskArbitration
    frameworks.Security
    frameworks.SystemConfiguration
    frameworks.CoreFoundation
    frameworks.IOKit
  ];
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
    autoconf
    automake
    libtool
    pkg-config
    hexdump
    which
    python3
    binutils-unwrapped
  ] ++ lib.optionals withGui [
    wrapQtAppsHook
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.cctools
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
  ] ++ lib.optionals stdenv.isDarwin darwinBuildInputs;

  # Set build environment
  NIX_CPP = if stdenv.isDarwin then "${stdenv.cc}/bin/cc -E" else "/usr/bin/cpp";

  # Make sure these are set before configure runs
    preConfigure = ''
    # Define BOOST_BIND_GLOBAL_PLACEHOLDERS to fix boost bind warning
    export CXXFLAGS="$CXXFLAGS -DBOOST_BIND_GLOBAL_PLACEHOLDERS -Wno-deprecated-declarations"
    export CPPFLAGS="$CPPFLAGS -DBOOST_BIND_GLOBAL_PLACEHOLDERS"
    
    # Export BDB paths
    export BDB_PREFIX="${db4}"
    export BDB_CFLAGS="-I${db4}/include"
    export BDB_LIBS="-L${db4}/lib -ldb_cxx-4.8"

    # Set library paths
    export BOOST_INCLUDE_PATH="${boost.dev}/include"
    export BOOST_LIB_PATH="${boost.out}/lib"
    export EVENT_INCLUDE_PATH="${libevent.dev}/include"
    export EVENT_LIB_PATH="${libevent.out}/lib"
    
    # Set compiler flags
    export NIX_CFLAGS_COMPILE="-I${boost.dev}/include -I${libevent.dev}/include -I${openssl.dev}/include -I${db4}/include"
    
    ${lib.optionalString stdenv.isDarwin ''
      export MACOSX_DEPLOYMENT_TARGET=11.0
      export CC="${stdenv.cc}/bin/cc"
      export CXX="${stdenv.cc}/bin/c++"
      export CXXFLAGS="$CXXFLAGS -std=c++17 -stdlib=libc++"
      export OBJCXX="${stdenv.cc}/bin/c++"
      export LDFLAGS="-L${lib.getLib openssl}/lib -L${boost.out}/lib -L${libevent.out}/lib -L${db4}/lib"
    ''}

    # Run autogen
    chmod +x autogen.sh
    ./autogen.sh
  '';

  configureFlags = [
    "--with-boost=${boost.dev}"
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
    "--disable-tests"
    "--with-daemon"
    "--with-utils"
    "--without-libs"
    "--with-incompatible-bdb"
    "--disable-dependency-tracking"
    "--disable-werror"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ] ++ lib.optionals stdenv.isDarwin [
    "--enable-hardening"
  ];

  # Fix header includes
  preBuild = lib.optionalString stdenv.isDarwin ''
    sed -i.bak '/#include <assert.h>/a\
    #include <deque>\
    #include <memory>\
    #include <utility>' src/httpserver.cpp
  '';

  enableParallelBuilding = true;
  makeFlags = [ "V=1" ];

  meta = with lib; {
    description = "DigiByte (DGB) is a rapidly growing decentralized, global blockchain";
    homepage = "https://digibyte.io/";
    license = licenses.mit;
    maintainers = [ maintainers.mmahut ];
    platforms = platforms.unix;
  };
}