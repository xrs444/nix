{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:

let
  # Define node-specific configurations
  nodeConfigs = {
    xsvr1 = {
      ip = "172.20.3.201";
      bindAddress = "172.20.3.201:8443";
    };
    xsvr2 = {
      ip = "172.20.3.202";
      bindAddress = "172.20.3.202:8443";
    };
    xsvr3 = {
      ip = "172.20.3.203";
      bindAddress = "172.20.3.203:8443";
    };
  };

  kanidmVip = "172.20.3.200";

  # Only set currentNode if hostname is in nodeConfigs
  currentNode = if lib.hasAttr hostname nodeConfigs then nodeConfigs.${hostname} else null;
in

if currentNode == null then
  {}
else
  {
    services.kanidm = {
      enableServer = true;
      serverSettings = {
        bindaddress = currentNode.bindAddress;
        ldapbindaddress = "${currentNode.ip}:3636";
        origin = "https://${kanidmVip}:8443";
        domain = "idm.xsvr.local";
        db_path = "/var/lib/kanidm/kanidm.db";
        tls_chain = "/var/lib/kanidm/chain.pem";
        tls_key = "/var/lib/kanidm/key.pem";
        online_backup = {
          path = "/var/lib/kanidm/backups";
          schedule = "00 22 * * *";
        };
      };
    };

    # Open required ports in firewall
    networking.firewall = {
      allowedTCPPorts = [ 
        8443  # Kanidm HTTPS
        3636  # Kanidm LDAP
      ];
    };

    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d /var/lib/kanidm 0700 kanidm kanidm"
      "d /var/lib/kanidm/backups 0700 kanidm kanidm"
    ];

    # Add SSL certificate management (you'll need to configure this based on your setup)
    environment.etc."kanidm-ssl-setup.sh".text = ''
      #!/bin/sh
      # Add your SSL certificate setup here
      echo "Configure SSL certificates for Kanidm"
    '';
    environment.etc."kanidm-ssl-setup.sh".mode = "0755";
  }