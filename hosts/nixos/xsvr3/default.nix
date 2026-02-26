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
    #    ./desktop.nix
    ./serial.nix
    ./vms.nix
    ./disks.nix
    ../../common
  ];

  # Remote builder configuration commented out - SSH key needs manual setup
  # Uncomment after manually creating /root/.ssh/id_builder on xsvr3
  # sops.secrets.builder_private_key = {
  #   sopsFile = ../../../secrets/builder-ssh-key.yaml;
  #   path = "/root/.ssh/id_builder";
  #   mode = "0600";
  # };

  # programs.ssh.knownHosts.xsvr1 = {
  #   hostNames = [
  #     "xsvr1"
  #     "xsvr1.lan"
  #   ];
  #   publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBT9D+yMvAWQk7DP4X0x3mCBp4sOF+Dl0cLG2K2Trc0W";
  # };

  # nix.buildMachines = [
  #   {
  #     hostName = "xsvr1";
  #     sshUser = "builder";
  #     sshKey = "/root/.ssh/id_builder";
  #     systems = [
  #       "x86_64-linux"
  #       "aarch64-linux"
  #     ];
  #     maxJobs = 8;
  #     speedFactor = 2;
  #     supportedFeatures = [
  #       "nixos-test"
  #       "benchmark"
  #       "big-parallel"
  #       "kvm"
  #     ];
  #     mandatoryFeatures = [ ];
  #   }
  # ];

  # nix.distributedBuilds = true;
  # nix.settings.builders-use-substitutes = true;

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
