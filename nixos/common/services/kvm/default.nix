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
    allowedBridges = [ "bridge16" "bridge17" "bridge21" ];
    extraConfig = ''
      listen_tls = 0
      listen_tcp = 1
      listen_addr "0.0.0.0"
      auth_tcp = "none"  # Warning: Use only in trusted networks
      unix_sock_group = "libvirt"
      unix_sock_rw_perms = "0770"
    '';
  };
};

# Open firewall ports
networking.firewall.allowedTCPPorts = [ 16509 5900 ];  # libvirt and VNC
}
