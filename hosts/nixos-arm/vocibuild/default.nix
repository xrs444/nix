# Summary: NixOS ARM host configuration for vocibuild — Oracle Cloud A1 Flex (aarch64) native Nix builder.
# Reachable via Tailscale MagicDNS as 'vocibuild'. No .lan DNS; all management via Tailscale.
# Bootstrapping sequence:
#   1. nixos-anywhere --flake .#vocibuild --target-host opc@<oracle-public-ip> --sudo
#   2. SSH in via public IP, run: tailscale up --authkey=<one-time-key>
#   3. Get age key: nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
#   4. Add age key to .sops.yaml, rekey secrets, create secrets/vocibuild-tailscale.yaml
#   5. Redeploy via CI to pick up SOPS Tailscale auth key
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

  # SOPS Tailscale pre-auth key — populated post-bootstrap (see bootstrapping sequence above).
  # Uncomment after adding vocibuild age key to .sops.yaml and creating the secret file.
  # sops.secrets.tailscale_authkey = {
  #   sopsFile = ../../../secrets/vocibuild-tailscale.yaml;
  # };
  # services.tailscale.authKeyFile = "/run/secrets/tailscale_authkey";

  # Tailscale enabled without authKeyFile for initial install.
  # First-boot connection is manual: ssh in via Oracle public IP, run tailscale up --authkey=...
  services.tailscale.enable = true;

  # Oracle Cloud Security Lists + firewall: allow SSH from everywhere during bootstrap.
  # After Tailscale is up, consider tightening to tailscale0 only.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Open monitoring exporter ports on the Tailscale interface only.
  # node_exporter (9100) and alloy (9080) scraped by Prometheus on xsvr1 via Tailscale.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
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
