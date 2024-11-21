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
    owner = "jgarzik";  # Changed from bitcoin-core to jgarzik
    repo = "univalue";
    rev = "89c61d10628fff53ada752660dcd4b4d515a5a31";  # Using specific commit hash
    hash = "sha256-qZBhK4FoGNcnj8oH2tpJ/OhbRFTZFOYlJGp4jMi4Zhk=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  configureFlags = [
    "--enable-static"
    "--disable-shared"
  ];

  # Added to fix potential autotools issues
  preConfigure = ''
    autoreconf -vi
  '';

  meta = with lib; {
    description = "Universal Value object and JSON library";
    homepage = "https://github.com/jgarzik/univalue";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}