# Summary: NixOS ARM host configuration for xlt1-t-vnixos, imports hardware, disk, and desktop modules.
{
  hostname,
  platform,
  lib,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ./disks.nix
    ./desktop.nix
    ../../common
  ];

  nixpkgs.hostPlatform = platform;

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;

  # Builder-specific GC: daily schedule + automatic free-space trigger.
  # Weekly GC (base-nixos.nix) is too infrequent for a remote builder —
  # failed builds accumulate quickly and exhaust disk, causing spurious
  # ENOSPC failures on legitimate subsequent builds. Same pattern as
  # xsvr1/xsvr2/xsvr3/vocibuild. xlt1-t-vnixos is part of the builder
  # pool (modules/services/remotebuilds/default.nix) as the native
  # aarch64 VM builder.
  nix.gc = {
    automatic = true;
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 7d";
  };
  nix.settings = {
    # Trigger GC automatically if store drops below 10 GiB free,
    # stopping once 50 GiB is reclaimed. Fires mid-build if needed.
    min-free = 10737418240; # 10 GiB
    max-free = 53687091200; # 50 GiB
  };
}
