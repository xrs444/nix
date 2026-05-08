# Summary: NixOS host configuration for xcomm1, imports hardware, audio, and disk modules.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-amd.nix
    ../common/audio-pipewire.nix
    ../common/boot.nix
    ./network.nix
    ./desktop.nix
    ./disks.nix
    ./wake.nix
    ../../common
  ];

  networking.hostName = "xcomm1";
  nixpkgs.config.allowUnfree = true;

  # Open monitoring exporter ports on the WiFi interface (xcomm1 uses wlp6s0, not bond0)
  # The common exporters.nix only opens on bond0 which doesn't exist here.
  networking.firewall.interfaces.wlp6s0.allowedTCPPorts = [
    9080 # promtail
    9100 # node_exporter
    9633 # smartctl_exporter
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
      ];
    };
};
}
