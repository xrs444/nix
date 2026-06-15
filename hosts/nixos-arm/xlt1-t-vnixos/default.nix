# Summary: NixOS ARM host configuration for xlt1-t-vnixos, imports hardware, disk, and desktop modules.
{
  hostname,
  platform,
  ...
}:
{
  imports = [
    ../../base-nixos.nix
    ../common/hardware-arm64-server.nix
    ./disks.nix
    # desktop.nix omitted for initial install: desktop pulls in sdl3/ffmpeg which
    # time out building under QEMU. Auto-upgrade will deploy full config once this
    # host is running as a native aarch64 builder.
    #    ./desktop.nix
    #    ./network.nix
    ../../common
  ];

  nixpkgs.hostPlatform = platform;

  networking.hostName = hostname;

  nixpkgs.config.allowUnfree = true;
}
