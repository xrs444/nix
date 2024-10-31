{ pkgs, ... }:
{
  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "/home/thomas-local/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep-since 10d --keep 3";
    };
  };
}
