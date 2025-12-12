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
      openFirewall = true;
    };
  };
}
