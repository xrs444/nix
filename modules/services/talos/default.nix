# Summary: NixOS module for Talos, configures firewall and trusted interfaces for Talos cluster hosts.
{
  config,
  hostname,
  hostRoles ? [ ],
  lib,
  pkgs,
  platform,
  ...
}:
let
  hasRole = lib.elem "talos" hostRoles;

in
{
  config = lib.mkIf hasRole {
    networking.firewall = {
      trustedInterfaces = [
        "bond0.22"
        "bond0.21"
        "bond0.17"
        "bond0.16"
      ];
      allowedTCPPorts = [
        50000
        50001
        80
        443
      ];
      allowedUDPPorts = [
        50000
        50001
      ];
    };
  };
}
