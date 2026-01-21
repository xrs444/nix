# Summary: vsftpd configuration for xsvr1, provides FTP access for Omada backups with retention management.
{ pkgs, config, ... }:
{
  # Sops secret for omada-ftp password
  sops.secrets."omada-ftp-password" = {
    sopsFile = ../../../secrets/omada-ftp.yaml;
    key = "hashed_password";
    neededForUsers = true;
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
      chown -R omada-ftp:omada-ftp /zfs/systembackups/omada
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
      # Chroot users to their home directory
      chroot_local_user=YES
      allow_writeable_chroot=YES

      # Only allow users in userlist
      userlist_deny=NO

      # Disable anonymous access
      anonymous_enable=NO

      # Local users can login
      local_enable=YES

      # Security settings
      ssl_enable=NO
      force_local_logins_ssl=NO
      force_local_data_ssl=NO

      # Logging
      xferlog_enable=YES
      xferlog_file=/var/log/vsftpd.log

      # Performance
      use_localtime=YES
    '';
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [
    21 # FTP control
  ];

  networking.firewall.allowedTCPPortRanges = [
    { from = 50000; to = 50100; } # FTP passive mode data
  ];
}
