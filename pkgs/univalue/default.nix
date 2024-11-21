# ./pkgs/univalue/default.nix:

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