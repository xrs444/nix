{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Only xsvr1 and xsvr2 should run kanidm servers
  isKanidmServer = builtins.elem hostname ["xsvr1" "xsvr2"];
  
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
in
lib.mkMerge [

  # Import the provisioning module
  (import ./provision.nix { inherit config hostname lib pkgs; })

  # Override package for servers only
  (lib.mkIf isKanidmServer {
    services.kanidm.package = lib.mkForce pkgs.kanidmProvision;
  })

  # NixOS server configuration
  (lib.mkIf isKanidmServer {
 
    services.kanidm = {
      enableServer = true;
      enableClient = true;   # Enable client for authentication
      enablePam = true;      # Enable PAM but configure properly
      # package setting moved to separate mkIf block above
      
      clientSettings = {
        uri = kanidmServerUri;
      };
      
      serverSettings = {
        bindaddress = "0.0.0.0:8443";
        ldapbindaddress = "0.0.0.0:3636";
        origin = "https://idm.xrs444.net";
        domain = "idm.xrs444.net";
        tls_chain = "/var/lib/kanidm/certs/chain.pem";
        tls_key = "/var/lib/kanidm/certs/key.pem";
      };
    };

    # Configure PAM to try Kanidm first, then fall back to local
    security.pam.services = {
      login.text = lib.mkForce ''
        auth       sufficient pam_kanidm.so ignore_unknown_user
        auth       sufficient pam_unix.so nullok
        auth       required   pam_deny.so

        account    sufficient pam_kanidm.so ignore_unknown_user
        account    sufficient pam_unix.so
        account    required   pam_deny.so

        password   sufficient pam_kanidm.so
        password   sufficient pam_unix.so nullok sha512
        password   required   pam_deny.so

        session    optional   pam_keyinit.so revoke
        session    optional   pam_kanidm.so
        session    required   pam_limits.so
        session    optional   pam_systemd.so
        session    required   pam_unix.so
        session    optional   pam_mkhomedir.so skel=/etc/skel umask=077
      '';
      
      sshd.text = lib.mkForce ''
        auth       sufficient pam_kanidm.so ignore_unknown_user
        auth       sufficient pam_unix.so nullok
        auth       required   pam_deny.so

        account    sufficient pam_kanidm.so ignore_unknown_user
        account    sufficient pam_unix.so
        account    required   pam_deny.so

        password   sufficient pam_kanidm.so
        password   sufficient pam_unix.so nullok sha512
        password   required   pam_deny.so

        session    optional   pam_keyinit.so revoke
        session    optional   pam_kanidm.so
        session    required   pam_limits.so
        session    optional   pam_systemd.so
        session    required   pam_unix.so
        session    optional   pam_mkhomedir.so skel=/etc/skel umask=077
      '';
    };

    # Enable mkhomedir for automatic home directory creation
    security.pam.enableMkHomeDir = true;

    # Open firewall ports for kanidm
    networking.firewall = {
      allowedTCPPorts = [ 8443 3636 ];
    };

    # Configure Let's Encrypt for idm.xrs444.net
    security.acme.certs."idm.xrs444.net" = {
      domain = "idm.xrs444.net";
      extraDomainNames = [];
    };

    # Link the ACME certificates to kanidm's expected location
    systemd.services.kanidm-link-certs = {
      description = "Link ACME certificates for Kanidm";
      after = [ "acme-idm.xrs444.net.service" ];
      wants = [ "acme-idm.xrs444.net.service" ];
      wantedBy = [ "kanidm.service" ];
      before = [ "kanidm.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "kanidm";
        Group = "kanidm";
      };
      
      script = ''
        mkdir -p /var/lib/kanidm/certs
        ln -sf /var/lib/acme/idm.xrs444.net/fullchain.pem /var/lib/kanidm/certs/chain.pem
        ln -sf /var/lib/acme/idm.xrs444.net/key.pem /var/lib/kanidm/certs/key.pem
        chown -R kanidm:kanidm /var/lib/kanidm/certs
      '';
    };
  })

]