# VM guest configuration for ARM systems
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Virtualization guest features
  virtualisation.hypervKvpDaemon.enable = lib.mkDefault false; # Not typically available on ARM
  
  # QEMU guest agent for ARM VMs
  services.qemuGuest.enable = lib.mkDefault true;
  
  # Spice agent for GUI VMs (when available)
  services.spice-vdagentd.enable = lib.mkDefault false;
  
  # Virtio modules for ARM VMs
  boot.initrd.availableKernelModules = lib.mkDefault [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "9p"
    "9pnet_virtio"
  ];
  
  # Filesystem support for VM guests
  boot.initrd.kernelModules = lib.mkDefault [ "virtio_balloon" ];
  
  # Network configuration for VMs
  networking.useDHCP = lib.mkDefault true;
  
  # Disable hardware-specific services that don't make sense in VMs
  services.thermald.enable = lib.mkDefault false;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  
  # Enable VM-specific optimizations
  fileSystems."/" = {
    options = lib.mkDefault [ "noatime" ];
  };
}