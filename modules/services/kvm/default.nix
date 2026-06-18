# Summary: NixOS module for KVM virtualization, installs QEMU and virt-manager for selected hosts.
{
  hostRoles ? [ ],
  isWorkstation ? false,
  lib,
  pkgs,
  ...
}:
let
  hasRole = lib.elem "kvm" hostRoles;
in
lib.mkIf hasRole {

  environment.systemPackages =
    with pkgs;
    [
      (if isWorkstation then qemu else qemu.override { gtkSupport = false; })
      OVMF
    ]
    ++ lib.optionals isWorkstation [
      virt-manager
      quickemu
    ];

  programs.virt-manager.enable = isWorkstation;
  users.groups.libvirtd.members = [ "thomas-local" ];

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
      onShutdown = "shutdown";
      qemu = {
        package =
          if isWorkstation then
            pkgs.qemu_kvm
          else
            pkgs.qemu_kvm.override {
              gtkSupport = false;
              sdlSupport = false;
              openGLSupport = false;
              virglSupport = false;
            };
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
