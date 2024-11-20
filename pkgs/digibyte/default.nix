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
  ] ++ lib.optionals withGui [
    qtbase
    qttools
    protobuf
  ] ++ lib.optionals stdenv.isDarwin darwinBuildInputs;

  # Override the default preprocessor
  NIX_CPP = if stdenv.isDarwin then "${stdenv.cc}/bin/cc -E" else "/usr/bin/cpp";

  # Make sure these are set before configure runs
  preConfigure = ''
    # Override cpp path in configure script
    substituteInPlace configure.ac \
      --replace 'AC_PROG_CPP' '
    AC_MSG_CHECKING(how to run the C preprocessor)
    CPP="${stdenv.cc}/bin/cc -E"
    AC_MSG_RESULT($CPP)'

    export BOOST_INCLUDE_PATH="${boost.dev}/include"
    export BOOST_LIB_PATH="${boost.out}/lib"
    export EVENT_INCLUDE_PATH="${libevent.dev}/include"
    export EVENT_LIB_PATH="${libevent.out}/lib"
    export BDB_INCLUDE_PATH="${db4}/include"
    export BDB_LIB_PATH="${db4}/lib"
    export NIX_CFLAGS_COMPILE="-I${boost.dev}/include -I${libevent.dev}/include -I${openssl.dev}/include -I${db4}/include"
    
    ${lib.optionalString stdenv.isDarwin ''
      export MACOSX_DEPLOYMENT_TARGET=11.0
      export CC="${stdenv.cc}/bin/cc"
      export CXX="${stdenv.cc}/bin/c++"
      export CXXFLAGS="-std=c++17 -stdlib=libc++"
      export OBJCXX="${stdenv.cc}/bin/c++"
      export LDFLAGS="-L${lib.getLib openssl}/lib -L${boost.out}/lib -L${libevent.out}/lib -L${db4}/lib"
    ''}

    # Run autogen
    ./autogen.sh
  '';

  configureFlags = [
    "--with-boost=${boost.dev}"
    "--with-boost-libdir=${boost.out}/lib"
    "--disable-bench"
    "--disable-tests"
    "--with-system-univalue"
    "--disable-dependency-tracking"
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ] ++ lib.optionals stdenv.isDarwin [
    "--enable-hardening"
    "--with-daemon"
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