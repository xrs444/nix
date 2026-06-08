{ ... }:
{
  imports = [
    ../../base-nixos.nix
    ../../../modules/packages-workstation
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    ./hardware-nvidia.nix
    ../../common
  ];

  networking.hostName = "xdt1-t";
  nixpkgs.config.allowUnfree = true;

  # Wired NIC is enp8s0 (confirmed from installer). Open monitoring exporter ports.
  networking.firewall.interfaces.enp8s0.allowedTCPPorts = [ 9080 9100 9633 ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];

  # nvme must be in kernelModules (not just availableKernelModules) so it is
  # loaded before systemd-initrd attempts to mount the root filesystem.
  boot.initrd.kernelModules = [ "nvme" ];
}
