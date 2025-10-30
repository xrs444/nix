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

services.cockpit = {
  enable = true;
  openFirewall = true; 
  };
}