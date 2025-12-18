# Summary: NixOS module for Home Assistant, installs and configures Home Assistant for selected hosts.
{
  hostRoles ? [ ],
  lib,
  ...
}:
let
  hasRole = lib.elem "homeassistant" hostRoles;
in
lib.mkIf hasRole {

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
    16509 # virt-manager
    8123
    443
    80
  ];

}
