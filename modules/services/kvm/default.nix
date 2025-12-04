# Summary: NixOS module for KVM virtualization, installs QEMU and virt-manager for selected hosts.
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
lib.mkIf (lib.elem "${hostname}" installOn) {

  environment.systemPackages = with pkgs; [
    qemu
    virt-manager
    quickemu
    OVMF
  ];

  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "thomas-local" ];

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
      };
      allowedBridges = [
        "bridge16"
        "bridge17"
        "bridge21"
        "bridge22"
      ];
      extraConfig = ''
        listen_tls = 0
        listen_tcp = 1
        listen_addr = "0.0.0.0"
        auth_tcp = "none"  # Warning: Use only in trusted networks
        unix_sock_group = "libvirtd"
        unix_sock_rw_perms = "0770"
      '';
    };
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [
    16509
    5900
  ]; # libvirt and VNC
}
