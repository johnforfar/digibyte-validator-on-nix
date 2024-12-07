# ./container.nix

{ config, pkgs, ... }: {
  containers.digibyte = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.250.0.1";
    localAddress = "10.250.0.2";
    
    config = { config, pkgs, ... }: {
      system.stateVersion = "24.05";

      # Service configuration
      systemd.services.digibyte = {
        description = "DigiByte Node";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        
        environment = {
          DIGIBYTE_HOME = "/var/lib/digibyte";
          DIGIBYTE_CONFIG = "/var/lib/digibyte/digibyte.conf";
        };
        
        serviceConfig = {
          Type = "simple";
          User = "digibyte";
          Group = "digibyte";
          StateDirectory = "digibyte";
          RuntimeDirectory = "digibyte";
          ExecStart = "${pkgs.digibyte}/bin/digibyted -daemon -conf=/var/lib/digibyte/digibyte.conf";
          ExecStop = "${pkgs.digibyte}/bin/digibyte-cli -conf=/var/lib/digibyte/digibyte.conf stop";
          Restart = "on-failure";
        };
      };

      # Network configuration
      networking.firewall.allowedTCPPorts = [ 12024 14022 3333 ];
      
      # User/group setup
      users.users.digibyte = {
        isSystemUser = true;
        group = "digibyte";
        home = "/var/lib/digibyte";
        createHome = true;
      };
      users.groups.digibyte = {};
    };
  };
}