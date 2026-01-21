# Summary: vsftpd configuration for xsvr1, provides FTP access for Omada backups with retention management.
{ pkgs, config, ... }:
{
  # Sops secret for omada-ftp password
  sops.secrets."omada-ftp-password" = {
    sopsFile = ../../../secrets/omada-ftp.yaml;
    key = "hashed_password";
    neededForUsers = true;
    mode = "0400";
    owner = "root";
    group = "root";
  };

  # Create the omada FTP user
  users.users.omada-ftp = {
    isSystemUser = true;
    group = "omada-ftp";
    home = "/zfs/systembackups/omada";
    createHome = true;
    shell = "${pkgs.shadow}/bin/nologin";
    hashedPasswordFile = config.sops.secrets."omada-ftp-password".path;
  };

  # Workaround: Ensure password is set in shadow file
  system.activationScripts.omada-ftp-password = {
    text = ''
      # Read the password hash from sops secret
      if [ -f "${config.sops.secrets."omada-ftp-password".path}" ]; then
        HASH=$(cat "${config.sops.secrets."omada-ftp-password".path}")
        # Use usermod to set the password hash
        ${pkgs.shadow}/bin/usermod -p "$HASH" omada-ftp || true
      fi
    '';
    deps = [ "users" ];
  };

  users.groups.omada-ftp = {};

  # Ensure the backup directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /zfs/systembackups 0755 root root -"
    "d /zfs/systembackups/omada 0755 omada-ftp omada-ftp -"
  ];

  # Ensure ownership is set after user creation
  systemd.services.vsftpd-setup = {
    description = "Setup vsftpd directory permissions";
    wantedBy = [ "vsftpd.service" ];
    before = [ "vsftpd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /zfs/systembackups/omada
      chown omada-ftp:omada-ftp /zfs/systembackups/omada
      chmod 755 /zfs/systembackups/omada
    '';
  };

  # Configure vsftpd
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    userlist = [ "omada-ftp" ];
    userlistEnable = true;

    extraConfig = ''
      # Listen on both IPv4 and IPv6 (dual-stack)
      # Setting listen=NO and listen_ipv6=YES enables dual-stack mode
      listen=NO
      listen_ipv6=YES

      # Chroot users to their home directory
      chroot_local_user=YES
      allow_writeable_chroot=YES

      # Only allow users in userlist
      userlist_deny=NO

      # Disable anonymous access
      anonymous_enable=NO

      # Local users can login
      local_enable=YES

      # Use PAM for authentication
      pam_service_name=vsftpd

      # Security settings
      ssl_enable=NO
      force_local_logins_ssl=NO
      force_local_data_ssl=NO
      seccomp_sandbox=NO

      # Logging
      xferlog_enable=YES
      xferlog_file=/var/log/vsftpd.log
      log_ftp_protocol=YES
      debug_ssl=YES

      # Performance
      use_localtime=YES

      # File operations
      file_open_mode=0755
      local_umask=022
    '';
  };

  # Open firewall ports for both IPv4 and IPv6
  networking.firewall.allowedTCPPorts = [
    21 # FTP control
  ];

  networking.firewall.allowedTCPPortRanges = [
    { from = 50000; to = 50100; } # FTP passive mode data (IPv4 & IPv6)
  ];

  # Explicitly allow IPv6 as well
  networking.firewall.extraCommands = ''
    # Allow FTP data connections for IPv6
    ip6tables -A nixos-fw -p tcp --dport 50000:50100 -j nixos-fw-accept || true
  '';
}
