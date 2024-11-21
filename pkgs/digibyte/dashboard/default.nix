{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation {
  name = "digibyte-dashboard";
  
  src = ./.;
  
  buildInputs = [
    pkgs.nodejs
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/dashboard

    # Copy dashboard files
    cp $src/index.html $out/share/dashboard/index.html
    cp $src/server.js $out/share/dashboard/server.js

    # Create executable wrapper
    cat > $out/bin/digibyte-dashboard <<EOF
    #!${pkgs.nodejs}/bin/node
    require('$out/share/dashboard/server.js')
    EOF
    chmod +x $out/bin/digibyte-dashboard
  '';

  meta = with pkgs.lib; {
    description = "DigiByte Node Dashboard";
    platforms = platforms.unix;
  };
}