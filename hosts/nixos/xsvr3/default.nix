# Summary: NixOS host configuration for xsvr3, imports hardware, boot, desktop, and VM modules.
{
  inputs,
  hostname,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-intel.nix
    ../common/boot.nix
    ../common/performance.nix
    ./network.nix
    ./desktop.nix
    ./serial.nix
    ./vms.nix
    ./disks.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  # Use xsvr1 as remote builder for heavy packages
  nix.buildMachines = [
    {
      hostName = "xsvr1";
      sshUser = "builder";
      sshKey = "/root/.ssh/id_builder";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
    }
  ];

  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  boot.initrd = {
    availableKernelModules = [
      "mpt3sas"
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "dm_mod"
    ];
  };

  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
}
