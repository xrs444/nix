{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

let
  # Kanidm server URI points to the VIP
  kanidmServerUri = "https://idm.xrs444.net";
  
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;
  
  # Use the kanidm from our overlay (which points to unstable.kanidm_1_7)
  kanidmPackage = pkgs.kanidm;
in
lib.mkMerge [
  # Common packages for all systems
  {
    environment.systemPackages = with pkgs; [
      kanidmPackage 
    ];
  }

  # Darwin-specific configuration
  (lib.mkIf isDarwin {
    # Darwin-specific kanidm client setup if needed
  })

  # NixOS client configuration
  (lib.mkIf (!isDarwin) {
    services.kanidm = {
      enableClient = true;
      package = lib.mkForce kanidmPackage;
      clientSettings = {
        uri = kanidmServerUri;
        verify_ca = true;
        verify_hostnames = true;
      };
    };

    # Configure PAM to try local auth first, then kanidm
    security.pam.services = {
      sshd.text = lib.mkBefore ''
        auth sufficient pam_unix.so nullok
        account sufficient pam_unix.so
      '' + lib.mkAfter ''
        auth sufficient pam_kanidm.so
        account sufficient pam_kanidm.so
      '';
      
      sudo.text = lib.mkBefore ''
        auth sufficient pam_unix.so nullok
      '' + lib.mkAfter ''
        auth sufficient pam_kanidm.so
      '';
      
      login.text = lib.mkBefore ''
        auth sufficient pam_unix.so nullok
        account sufficient pam_unix.so
      '' + lib.mkAfter ''
        auth sufficient pam_kanidm.so
        account sufficient pam_kanidm.so
      '';
    };

    # Ensure NSS prioritizes local files over kanidm
    system.nssDatabases = {
      passwd = [ "files" "systemd" ];
      group = [ "files" "systemd" ];
      shadow = [ "files" ];
    };

    systemd.services.kanidm-unixd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
    };
  })
]