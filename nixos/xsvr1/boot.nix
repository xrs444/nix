{ pkgs, lib, ... }:
{
  boot = {
    # Secure boot configuration
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd = {
      availableKernelModules = [
        "mpt3sas"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod" 
      ];
      kernelModules = [
        "kvm-amd" 
      ];
    };

      swraid = {
      enable = true;
      mdadmConf = "PROGRAM=true";
    };
    boot.swraid.enable = true;

    # Use the latest Linux kernel, rather than the default LTS
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };


}
