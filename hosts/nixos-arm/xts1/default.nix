# Summary: NixOS ARM host configuration for xts1, imports boot, hardware, and Raspberry Pi modules.
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
    ../common/hardware-rpi.nix
    ../../../modules/hardware/RaspberryPi4
    ./network.nix
    ../../common
  ];

  networking.hostName = hostname;

  # Bootloader configuration for Raspberry Pi
  boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

  # Disable generic initrd modules not available in RPi4 kernel
  boot.initrd.includeDefaultModules = false;

  # Filter out modules that don't exist in the RPi4 kernel (renamed/removed in 6.12)
  boot.initrd.availableKernelModules = lib.mkForce [
    "usbhid"
    "usb-storage"
    "vc4"
    "pcie-brcmstb"
    "reset-raspberrypi"
    "sdhci_pci"
    "mmc_block"
    "ext4"
    "nvme"
  ];

  # Ensure boot partition is writable during rebuild
  boot.loader.generic-extlinux-compatible.configurationLimit = 10;

  # Force the system to use the correct profile path
  system.activationScripts.fixProfile = lib.stringAfter [ "users" ] ''
    rm -f /nix/var/nix/profiles/system
    ln -sf /nix/var/nix/profiles/system-profiles/xts1 /nix/var/nix/profiles/system
  '';

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  hardware.i2c.enable = true;
  hardware.raspberry-pi."4".poe-plus-hat.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Proxy .ts.net DNS to Tailscale magic DNS (100.100.100.100 is only reachable
  # on Tailscale nodes like xts1/xts2). Firewalla forwards .ts.net here instead
  # of directly to 100.100.100.100, which is unreachable from non-Tailscale hosts.
  # Listening on tailscale0 allows DNS to also work when accessed via Tailscale IP.
  services.dnsmasq = {
    enable = true;
    settings = {
      server = [ "/ts.net/100.100.100.100" ];
      interface = [ "lo" "end0" "tailscale0" ];
      # bind-dynamic: like bind-interfaces but picks up IPs added after startup
      # (keepalived VIP and tailscale0 both come up after dnsmasq starts)
      bind-dynamic = true;
      # Disable negative caching: at boot, dnsmasq starts before Bird installs
      # the 100.64.0.0/10 route via the Tailscale socket, so the first ts.net
      # forward fails. Without no-negcache, that NXDOMAIN is cached until restart.
      no-negcache = true;
    };
  };
  # Wait for Bird to install the 100.64.0.0/10 route via the Tailscale socket before
  # dnsmasq starts. Without this, the first ts.net forward to 100.100.100.100 fails
  # (no route), the Firewalla caches the NXDOMAIN, and all clients get NXDOMAIN until
  # the Firewalla is restarted.
  systemd.services.dnsmasq = {
    after = [ "tailscaled.service" "bird.service" ];
    preStart = lib.mkBefore ''
      echo "Waiting for Bird to install 100.64.0.0/10 via tailscale0..."
      for i in $(seq 30); do
        ${pkgs.iproute2}/bin/ip route show 100.64.0.0/10 | grep -q tailscale0 && break
        sleep 1
      done
    '';
  };
  networking.firewall.allowedUDPPorts = [ 53 ];
  networking.firewall.allowedTCPPorts = [ 53 ];

  # SD card filesystem layout (NixOS SD image convention)
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
    options = [ "nofail" ];
  };
}
