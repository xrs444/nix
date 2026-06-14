# Summary: TFTP server for network device provisioning (switch SSH key import, PXE boot, etc.)
{ hostname, lib, pkgs, ... }:
let
  tftpHosts = [ "xsvr1" ];
  isServer = lib.elem hostname tftpHosts;
in
lib.mkIf isServer {
  # Use tftp-hpa standalone daemon instead of netkit-tftp-0.17 via xinetd.
  # netkit-tftp-0.17 (1999) mishandles the IPv4-mapped IPv6 sockaddr that xinetd
  # passes on dual-stack systems, causing DATA packets to go to the wrong address.
  # tftp-hpa binds explicitly to 0.0.0.0:69 (IPv4 only) and runs as a single daemon.
  systemd.services.tftpd = {
    description = "TFTP server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.tftp-hpa}/sbin/in.tftpd --listen --user nobody --address 0.0.0.0:69 --secure /zfs/tftp";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # wheel group can write files here (e.g. via scp for switch key provisioning)
  systemd.tmpfiles.rules = [
    "d /zfs/tftp 2775 root wheel -"
  ];

  networking.firewall.allowedUDPPorts = [ 69 ];
}
