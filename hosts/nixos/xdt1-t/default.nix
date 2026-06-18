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
    ./audio.nix
    ./disks.nix
    ./hardware-nvidia.nix
    ./shares.nix
    ../../common
  ];

  networking.hostName = "xdt1-t";
  nixpkgs.config.allowUnfree = true;

  # Determinate Nix ignores nix.conf for trusted-users — must be in nix.custom.conf.
  # Use extra-trusted-users so this appends to (rather than overrides) the
  # remotebuilds module's "trusted-users = root builder" line.
  environment.etc."nix/nix.custom.conf".text = ''
    extra-trusted-users = @wheel
  '';

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
