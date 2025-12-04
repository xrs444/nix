{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Inject SSH key into the image
  environment.etc."ssh/authorized_keys".text = "ssh-rsa AAAA...";

  # Inject WiFi config from sops secret
  sops.secrets.wifi = {
    sopsFile = ../../secrets/wan-wifi.yaml;
  };

  environment.etc."wpa_supplicant.conf".text =
    ''
      # Use wpa_supplicant's include directive to load secrets from SOPS-managed file
      include="${config.sops.secrets.wifi.path}"
    '';

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
