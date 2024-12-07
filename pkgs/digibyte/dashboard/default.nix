# ./pkgs/digibyte/dashboard/default.nix

{ pkgs ? import <nixpkgs> { }
, digibyted ? null
, lib ? pkgs.lib
}:

pkgs.stdenv.mkDerivation {
  name = "digibyte-dashboard";
  
  src = ./.;
  
  buildInputs = [
    pkgs.nodejs
    pkgs.bash
    pkgs.coreutils
    pkgs.procps
    pkgs.lsof
    pkgs.curl
    pkgs.util-linux
    digibyted
  ];

  installPhase = ''
    mkdir -p $out/bin $out/share/dashboard
    
    # Copy dashboard files
    cp "$src/index.html" "$out/share/dashboard/"
    cp "$src/server.js" "$out/share/dashboard/"
    
    # Create simple dashboard script
    cat > $out/bin/digibyte-dashboard <<EOF
    #!${pkgs.bash}/bin/bash
    cd $out/share/dashboard
    exec ${pkgs.nodejs}/bin/node server.js
    EOF
    
    chmod +x $out/bin/digibyte-dashboard
  '';

  meta = with lib; {
    description = "DigiByte Node Dashboard";
    platforms = platforms.unix;
    homepage = "https://digibyte.io";
    license = licenses.mit;
  };
}