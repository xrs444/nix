{
  hostname,
  lib,
  platform,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;

  services.nfs.server = {
    enable = true;
    createMountPoints = true;
    exports = ''
      /export *(rw,no_subtree_check,fsid=0)
    '';
  };
  services.rpcbind.enable = true;

  networking.firewall.allowedTCPPorts = [
    2049 # NFS
    111 # RPC portmapper
    20048 # NFS mountd
    32765 # statd
    32767 # mountd
    32769 # lockd
  ];
  networking.allowedUDPPorts = [
    2049 # NFS
    111 # RPC portmapper
    20048 # NFS mountd
    32765 # statd
    32767 # mountd
    32769 # lockd
  ];
}
