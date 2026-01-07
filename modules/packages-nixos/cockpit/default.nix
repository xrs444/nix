# Summary: NixOS module for Cockpit web console, enables and configures Cockpit for selected hosts.
{
  config,
  hostRoles ? [ ],
  lib,
  pkgs,
  ...
}:

let
  hasRole = lib.elem "cockpit" hostRoles;
in

{
  config = lib.mkIf hasRole {
    services.cockpit = {
      enable = true;
      port = 9091; # Changed from default 9090 to avoid conflict with Prometheus
      openFirewall = true;
    };

    # Update firewall to use new port
    networking.firewall.allowedTCPPorts = [ 9091 ];
  };
}
