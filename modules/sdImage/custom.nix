{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Networking: enable DHCP and NetworkManager for provisioning
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault true;

  # SSH for debugging and remote builds
  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings = {
    PasswordAuthentication = lib.mkDefault false;
    PermitRootLogin = lib.mkDefault "yes";
    PubkeyAuthentication = lib.mkDefault true;
    AuthorizedKeysFile = ".ssh/authorized_keys";
  };

  # Inject SSH key into the image
  environment.etc."ssh/authorized_keys".text = "ssh-rsa AAAA...";

  # Inject WiFi config from sops secret
  sops.secrets.wifi = {
    sopsFile = ../../secrets/wan-wifi.yaml;
  };
  environment.etc."wpa_supplicant.conf".text = ''
    # Use wpa_supplicant's include directive to load secrets from SOPS-managed file
    include="${config.sops.secrets.wifi.path}"
  '';

  # Enable comin for remote configuration
  services.comin.enable = true;
  services.comin.remotes = [
    {
      name = "origin";
      url = "https://github.com/xrs444/nix.git";
      branches.main.name = "main";
    }
  ];

  # Custom systemd service for first boot
  systemd.services."first-boot" = {
    description = "Custom first boot setup";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo First boot!'";
    };
  };

  # You can further override image partitioning or bootloader settings here if needed
}
