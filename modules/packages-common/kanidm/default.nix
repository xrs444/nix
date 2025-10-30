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
  
  # Use unstable kanidm to get 1.7.x
  kanidmPackage = pkgs.unstable.kanidm_1_7 or pkgs.kanidm_1_7;
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

    # Configure PAM for kanidm authentication
    security.pam.services = {
      sshd.text = lib.mkAfter ''
        auth sufficient pam_kanidm.so
        account sufficient pam_kanidm.so
      '';
      
      sudo.text = lib.mkAfter ''
        auth sufficient pam_kanidm.so
      '';
      
      login.text = lib.mkAfter ''
        auth sufficient pam_kanidm.so
        account sufficient pam_kanidm.so
      '';
    };

    systemd.services.kanidm-unixd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
    };
  })
]