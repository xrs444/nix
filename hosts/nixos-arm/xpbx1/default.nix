# Summary: NixOS ARM host configuration for xpbx1 - Raspberry Pi 3B running Asterisk PBX
# Provisioning: nginx serves device configs via HTTPS (xpbx1.xrs444.net); DHCP option 66 set on Firewalla → https://xpbx1.xrs444.net
# Replace MAC_* placeholders below with actual device MAC addresses (uppercase, no separators for
# Grandstream; lowercase no separators for Polycom; lowercase with colons for Sangoma).
{
  hostname,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/default.nix
    ../../../modules/hardware/RaspberryPi4 # Pi3B is similar to Pi4
    ../common/boot.nix
    ./disks.nix
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Disable only device tree overlays to avoid Python libfdt issue
  # Keep deviceTree enabled but clear overlays to bypass the broken builder
  hardware.deviceTree.overlays = lib.mkForce [];

  # Bootloader configuration for Raspberry Pi 3B
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi kernel
  boot.initrd.includeDefaultModules = false;

  # RPi3B kernel modules
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "mmc_block"
    "ext4"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Pi3B (39-bit VA) kernel rejects NixOS's hardening default of 33 for vm.mmap_rnd_bits.
  # CONFIG_ARCH_MMAP_RND_BITS_MAX is lower on Pi3 than Pi4 (48-bit VA). Use 18 (kernel default).
  boot.kernel.sysctl."vm.mmap_rnd_bits" = lib.mkForce 18;

  # Allow thomas-local to run switch-to-configuration without a password so
  # recovery (switch-to-configuration boot to fix the bootloader) can be done
  # over SSH. Store paths change per build so match with a glob.
  security.sudo.extraConfig = ''
    thomas-local ALL=(root) NOPASSWD: /nix/store/*/bin/switch-to-configuration *
  '';

  # BCM2835 hardware watchdog — auto-reboots if the kernel locks up (e.g. SD card I/O hang).
  # Without this, any freeze requires a manual power cycle.
  boot.kernelModules = [ "bcm2835_wdt" ];
  systemd.watchdog.runtimeTime = "30s";
  systemd.watchdog.rebootTime = "120s";

  # Keep /tmp in RAM to reduce SD card write cycles.
  boot.tmp.useTmpfs = true;

  # SD cards have no SMART data; the exporter finds no devices and either crashes or
  # produces nothing useful. Override the monitoring-client default (set in exporters.nix).
  services.prometheus.exporters.smartctl.enable = lib.mkForce false;

  # Open monitoring exporter and Asterisk HTTP ports on the LAN interface.
  # exporters.nix opens on bond0 which doesn't exist here; asterisk module opens 8088
  # globally but the global rule doesn't fire on this host — add it explicitly.
  networking.firewall.interfaces.enu1u1u1.allowedTCPPorts = [
    9080 # alloy (metrics)
    9100 # node_exporter
    8088 # Asterisk HTTP / Prometheus metrics
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    tmux
  ];

  nixpkgs.config.allowUnfree = true;
}
