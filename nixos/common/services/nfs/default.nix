{
  hostname,
  lib,
  ...
}:
{
  imports = lib.optional (builtins.pathExists (./. + "/${hostname}.nix")) ./${hostname}.nix;

  services.nfs.server = {
    enable = true;
    options = [ "nfsvers=4.2" ];

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
