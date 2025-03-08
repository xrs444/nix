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

programs.virt-manager.enable = true;
users.groups.libvirtd.members = ["thomas_local"];

virtualisation = { 
  libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
        ovmf = {
          enable = true;
          packages = [(pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd];
        };
    };
  };
};
}
