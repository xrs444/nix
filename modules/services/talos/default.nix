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
    "xsvr2"
    "xsvr3"
  ];

in
{
  config = lib.mkIf (lib.elem "${hostname}" installOn) {
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