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

  environment.systemPackages = with pkgs; [
    qemu
    virt-manager
    quickemu
  ];

virtualisation.libvirtd = {
  enable = true;
  };

}
