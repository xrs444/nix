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
  ];
in
lib.mkIf (lib.elem "${hostname}" installOn) {

virtualisation.libvirtd = {
  enable = true;
  extraPackages = with pkgs; [
    qemu
    virt-manager
    quickemu
    ];
  };

  networking.firewall.allowedTCPPorts = [
    5900 # VNC
    16509 # virt-manager
    8123
    443
    80
  ];

}