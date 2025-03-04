{
  hostname,
  lib,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;

  services.nfs.server = {
    enable = true;
    settings.nsfd = {
      vers2 = false;
      vers3 = false;
      vers4 = true;
      "vers4.0" = true;
      "vers4.1" = true;
      "vers4.2" = true;
    };
    exports = ''
      /export *(rw,no_subtree_check,fsid=0)
    '';
  };
  services.rpcbind.enable = true;

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
