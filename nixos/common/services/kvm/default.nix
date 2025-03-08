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

programs.virt-manager.enable = true;
users.groups.libvirtd.members = ["thomas-local"];

virtualisation = { 
  libvirtd = {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
        };
};

# Open firewall ports
networking.firewall.allowedTCPPorts = [ 16509 5900 ];  # libvirt and VNC
}
