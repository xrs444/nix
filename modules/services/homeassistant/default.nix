{
  config,
  hostname,
  lib,
  pkgs,
  platform,
  ...
}:
let
  installOn = [
    "xsvr1"
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
    16509 # virt-manager
    8123
    443
    80
  ];

}
