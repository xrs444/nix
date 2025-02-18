{
  hostname,
  lib,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;

  services.nfs.server = {
    enable = true;
    nfsd = {
      rdma = true;
      vers3 = false;
      vers4 = true;
      };
  };

  networking = {
    firewall = {
      allowedTCPPorts = [
        2049
      ];
      allowedUDPPorts = [
        2049
      ];
    };
  };
}
