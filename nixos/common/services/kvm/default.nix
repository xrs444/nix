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
    OVMF
  ];
security.polkit.enable = true;
programs.virt-manager.enable = true;
users.groups.libvirtd.members = ["thomas_local"];
networking.firewall.checkReversePath = false;

virtualisation = { 
  libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };
};
}
