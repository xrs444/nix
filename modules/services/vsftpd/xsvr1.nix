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

      # Enable passive mode for data connections
      pasv_enable=YES
      port_enable=YES

      # Passive mode port range
      pasv_min_port=50000
      pasv_max_port=50100

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
  networking.firewall = {
    allowedTCPPorts = [
      21 # FTP control
      20 # FTP data (active mode)
    ];
    # Passive mode port range
    allowedTCPPortRanges = [
      { from = 50000; to = 50100; }
    ];
  };
}
