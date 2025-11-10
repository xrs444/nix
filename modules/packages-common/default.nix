{ pkgs, ... }:

{
  imports = [
    ./kanidm
    ./tailscale
  ];

  # Common packages for all NixOS systems
  environment.systemPackages = with pkgs; [
    # Add common packages here
    openssl
    micro

  ];
}