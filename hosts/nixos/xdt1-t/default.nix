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

  # Open monitoring exporter ports — update NIC name (enp*/wlp*) after first boot
  # networking.firewall.interfaces.enp6s0.allowedTCPPorts = [ 9080 9100 9633 ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
  ];
}
