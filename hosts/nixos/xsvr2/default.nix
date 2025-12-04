# Summary: NixOS host configuration for xsvr2, imports hardware, boot, VM, and disk modules.
{
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
    ./vms.nix
    ./disks.nix
    # Common imports are now handled by hosts/common/default.nix
  ];

  # Add other heavy modules here as needed

  networking.hostName = hostname;
  networking.hostId = "8f9996ca";
  networking.useNetworkd = true;

  boot = {
    zfs.extraPools = [ "zpool-xsvr2" ];
    swraid = {
      enable = true;
      mdadmConf = ''
        MAILADDR xrs444@xrs444.net
      '';
    };
  };
  nixpkgs.config.allowUnfree = true;
}
