# Summary: TFTP server for network device provisioning (switch SSH key import, PXE boot, etc.)
{ hostname, lib, ... }:
let
  tftpHosts = [ "xsvr1" ];
  isServer = lib.elem hostname tftpHosts;
in
lib.mkIf isServer {
  services.tftpd = {
    enable = true;
    path = "/zfs/tftp";
  };

  # wheel group can write files here (e.g. via scp for switch key provisioning)
  systemd.tmpfiles.rules = [
    "d /zfs/tftp 2775 root wheel -"
  ];

  networking.firewall.allowedUDPPorts = [ 69 ];
}
