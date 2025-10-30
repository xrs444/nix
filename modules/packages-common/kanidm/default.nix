{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Kanidm server URI - can be overridden via specialArgs or environment
  kanidmServerUri = "https://idm.xrs444.net";
  
  # Check if we're on Darwin (macOS)
  isDarwin = pkgs.stdenv.isDarwin;
in
lib.mkMerge [
  # Common packages for both Darwin and NixOS
  {
    environment.systemPackages = with pkgs; [
      kanidm_1_7
    ];
  }

  # Darwin-specific configuration
  (lib.mkIf isDarwin {
    # Darwin-specific kanidm client setup if needed
    # Currently just the package installation above
  })

  # NixOS-specific configuration
  (lib.mkIf (!isDarwin) {
    # Kanidm Client Configuration (for external server)
    services.kanidm = {
      enableClient = true;
      package = pkgs.kanidm_1_7;
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

    # Ensure kanidm-unixd service is enabled for PAM integration
    systemd.services.kanidm-unixd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
    };
  })
]