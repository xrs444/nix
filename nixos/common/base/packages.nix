{ pkgs, isInstall, platform, ... }:
{
  basePackages = with pkgs; [
    bat
    binutils
    curl
    dig
    git
    killall
    nfs-utils
    rsync
    traceroute
    tree
    wget
    nix-output-monitor
      ]
  ++ lib.optionals isInstall [
    inputs.determinate.packages.${platform}.default
    inputs.fh.packages.${platform}.default
    inputs.nixos-needsreboot.packages.${platform}.default
    nvd
    nvme-cli
    smartmontools
    sops
  ];
}
