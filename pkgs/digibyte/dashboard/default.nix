{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation {
  name = "digibyte-dashboard";
  
  src = ./.;
  
  buildInputs = [
    pkgs.nodejs
    pkgs.nodePackages.express
  ];

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/dashboard

    # Copy dashboard files
    cp $src/index.html $out/share/dashboard/index.html
    cp $src/server.js $out/share/dashboard/server.js
    cp $src/package.json $out/share/dashboard/package.json

    # Create executable wrapper
    makeWrapper ${pkgs.nodejs}/bin/node $out/bin/digibyte-dashboard \
      --add-flags "$out/share/dashboard/server.js" \
      --set NODE_PATH ${pkgs.nodePackages.express}/lib/node_modules
  '';

  meta = with pkgs.lib; {
    description = "DigiByte Node Dashboard";
    platforms = platforms.unix;
    maintainers = [ ];
  };
}