# Update pkgs/digibyte/default.nix:

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
, univalue
, withGui ? false
, qtbase ? null
, qttools ? null
, wrapQtAppsHook ? null
, darwin ? null
}:

let
  # Define compiler paths for macOS
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

  depsBuildBuild = [ pkg-config ];
  
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
    univalue
  ] ++ lib.optionals withGui [
    qtbase
    qttools
    protobuf
  ] ++ lib.optionals stdenv.isDarwin darwinBuildInputs;

  # Override the default preprocessor
  NIX_CPP = if stdenv.isDarwin then "${stdenv.cc}/bin/cc -E" else "/usr/bin/cpp";

  # Make sure these are set before configure runs
  preConfigure = ''
    # Export BDB paths
    export BDB_PREFIX="${db4}"
    export BDB_CFLAGS="-I${db4}/include"
    export BDB_LIBS="-L${db4}/lib -ldb_cxx-4.8"

    # Set library paths
    export BOOST_INCLUDE_PATH="${boost.dev}/include"
    export BOOST_LIB_PATH="${boost.out}/lib"
    export EVENT_INCLUDE_PATH="${libevent.dev}/include"
    export EVENT_LIB_PATH="${libevent.out}/lib"
    
    # Add univalue to include and lib paths
    export UNIVALUE_INCLUDE_PATH="${univalue}/include"
    export UNIVALUE_LIB_PATH="${univalue}/lib"
    
    # Set compiler flags
    export NIX_CFLAGS_COMPILE="-I${boost.dev}/include -I${libevent.dev}/include -I${openssl.dev}/include -I${db4}/include -I${univalue}/include"
    
    ${lib.optionalString stdenv.isDarwin ''
      export MACOSX_DEPLOYMENT_TARGET=11.0
      export CC="${stdenv.cc}/bin/cc"
      export CXX="${stdenv.cc}/bin/c++"
      export CXXFLAGS="-std=c++17 -stdlib=libc++"
      export OBJCXX="${stdenv.cc}/bin/c++"
      export LDFLAGS="-L${lib.getLib openssl}/lib -L${boost.out}/lib -L${libevent.out}/lib -L${db4}/lib -L${univalue}/lib"
      export PKG_CONFIG_PATH="${univalue}/lib/pkgconfig:$PKG_CONFIG_PATH"
    ''}

    # Run autogen
    ./autogen.sh
  '';

  configureFlags = [
    "--with-boost=${boost.dev}"
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
    "--disable-tests"
    "--with-incompatible-bdb"
    "--with-daemon"
    "--with-univalue=${univalue}"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ] ++ lib.optionals stdenv.isDarwin [
    "--enable-hardening"
    "--enable-werror=no"
  ];

  # Fix header includes
  preBuild = lib.optionalString stdenv.isDarwin ''
    sed -i.bak '/#include <assert.h>/a\
    #include <deque>\
    #include <memory>\
    #include <utility>' src/httpserver.cpp
  '';

  # Enable verbose build output
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