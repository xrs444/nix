{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  installOn = [
    "xsvr1"
    "xsvr2"
    "xsvr3"
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

  virtualisation.podman.enable = true;

}
