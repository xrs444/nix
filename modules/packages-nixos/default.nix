{ pkgs, ... }:

{
  # Combined module
  default = { config, lib, pkgs, ... }: {
    imports = [
      ./cockpit
      (import ./comin)
      (import ./tailscale)
    ];

    # NixOS-specific packages
    environment.systemPackages = with pkgs; [
      # Add NixOS-specific packages here
    ];
  };
}