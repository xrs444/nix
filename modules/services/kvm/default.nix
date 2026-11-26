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
      # N4: libvirt's unauthenticated TCP listener (listen_tcp/auth_tcp="none" on 0.0.0.0,
      # 16509 open in the firewall) was removed 2026-11-26. It was not actually listening
      # (the TCP socket was never enabled) and nothing in either repo used it, but one
      # `systemctl enable libvirtd-tcp.socket` would have exposed root-equivalent control of
      # the host to the network. Manage libvirt over the local unix socket / ssh instead.
      extraConfig = ''
        listen_tls = 0
        unix_sock_group = "libvirtd"
        unix_sock_rw_perms = "0770"
      '';
    };
  };

  # No firewall ports opened: VNC (5900) is bound to localhost only, and libvirt is no
  # longer exposed over TCP (see the extraConfig note above).
}
