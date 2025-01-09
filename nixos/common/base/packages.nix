{ pkgs, ... }:
{
environment.systemPackages  = with pkgs; [
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
  ];
}
