# Summary: NixOS ARM host configuration for vocibuild — Oracle Cloud A1 Flex (aarch64) native Nix builder.
# Reachable via Tailscale MagicDNS as 'vocibuild'. No .lan DNS; all management via Tailscale.
# Bootstrapping sequence (one-time, only after disk wipe / nixos-anywhere reinstall):
#   1. nixos-anywhere --flake .#vocibuild --target-host opc@<oracle-public-ip> --sudo
#      NOTE: Oracle Security List must allow TCP 22 from your IP for this step.
#   2. SSH in via public IP, run: tailscale up --authkey=<one-time-key>
#      After this step, manage exclusively via Tailscale. Firewall blocks public SSH.
#   3. Get age key: nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
#   4. Add age key to .sops.yaml, rekey secrets, commit+push — CI deploys the rest.
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ../common/performance.nix
    ./disks.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Oracle Cloud uses virtio block/network. These must be in initrd so root mounts.
  boot.initrd.availableKernelModules = lib.mkForce [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "ahci"
    "nvme"
    "ext4"
    "xfs"
    "usbhid"
  ];

  # NVMe initrd module must be in kernelModules (not just availableKernelModules) per nixpkgs 26.05
  # systemd-initrd-by-default change: storage modules need to be present at initrd start.
  boot.kernelModules = [ "nvme" ];

  # Passwordless sudo — remote management without interactive password prompt.
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  # Tailscale: no authKeyFile — pre-auth keys have a 90-day max lifetime, making rotation painful.
  # Already-enrolled nodes reconnect automatically via persistent state in /var/lib/tailscale.
  # First-boot only: ssh in via Oracle public IP, run: tailscale up --authkey=<one-time-key>
  services.tailscale.enable = true;

  # SSH + monitoring only via Tailscale.
  # Oracle serial console (accessible from Oracle Cloud web UI) handles emergency access
  # if Tailscale is unreachable. No public SSH — bootstrap is the only exception and is
  # done via Oracle public IP before Tailscale is enrolled.
  # Override the shared openssh module which unconditionally sets openFirewall = true.
  services.openssh.openFirewall = lib.mkForce false;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    22   # SSH
    9080 # alloy
    9100 # node_exporter
  ];

  # Cloud VMs have no physical disks — SMART exporter finds nothing and errors.
  services.prometheus.exporters.smartctl.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    tmux
    htop
    nix-output-monitor
  ];

  nixpkgs.config.allowUnfree = true;
}
