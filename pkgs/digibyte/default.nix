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
, clang
, llvmPackages
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
    pkg-config
    autoreconfHook
    autoconf
    automake
    libtool
    which
    python3
  ] ++ lib.optionals withGui [
    wrapQtAppsHook
  ] ++ lib.optionals stdenv.isDarwin [
    darwin.cctools
    clang
    llvmPackages.bintools
  ];

  buildInputs = [
    boost
    libevent
    openssl
    db4
    zeromq
  ] ++ lib.optionals withGui [
    qtbase
    qttools
    protobuf
  ] ++ lib.optionals stdenv.isDarwin darwinBuildInputs;

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
  ] ++ lib.optionals withGui [
    "--with-gui=qt5"
    "--with-qt-bindir=${qtbase.dev}/bin:${qttools.dev}/bin"
  ] ++ lib.optionals stdenv.isDarwin [
    "--enable-hardening"
  ];

  preAutoreconf = ''
    # Ensure build-aux exists
    mkdir -p build-aux
    
    # Add missing includes
    cp src/httpserver.cpp src/httpserver.cpp.bak
    cat > src/httpserver.cpp << 'EOL'
    #include <deque>
    #include <memory>
    #include <utility>
    #include <vector>
    EOL
    cat src/httpserver.cpp.bak >> src/httpserver.cpp
    rm src/httpserver.cpp.bak
  '';

  preConfigure = ''
    # Add BerkeleyDB paths
    export BDB_PREFIX="${db4}"
    
    ${lib.optionalString stdenv.isDarwin ''
      export MACOSX_DEPLOYMENT_TARGET=11.0
      export LDFLAGS="-L${lib.getLib openssl}/lib -L${boost.out}/lib -L${libevent.out}/lib -L${db4}/lib"
    ''}
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "DigiByte (DGB) is a rapidly growing decentralized, global blockchain";
    homepage = "https://digibyte.io/";
    license = licenses.mit;
    maintainers = [ maintainers.mmahut ];
    platforms = platforms.unix;
  };
}