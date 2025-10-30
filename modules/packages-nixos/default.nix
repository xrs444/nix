{ config, lib, pkgs, ... }:

{
  imports = [
    ./cockpit
    ./comin
    ./tailscale
  ];

  # NixOS-specific packages
  environment.systemPackages = with pkgs; [
    # Add NixOS-specific packages here
  ];
}